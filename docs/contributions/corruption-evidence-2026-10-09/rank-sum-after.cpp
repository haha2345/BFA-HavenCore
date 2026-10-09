#include <algorithm>
#include <cstdint>
#include <iostream>
#include <map>
#include <vector>
#include <set>
#include <string>
using uint8=uint8_t; using uint32=uint32_t; using int32=int32_t; using SpellEffIndex=int;
constexpr int EQUIPMENT_SLOT_START=0,EQUIPMENT_SLOT_END=19,INVENTORY_SLOT_BAG_0=0,ITEM_SPELLTRIGGER_ON_EQUIP=1;
#define TC_LOG_ERROR(...) ((void)0)
struct Player; struct Unit;
struct Guid { int value=0; bool IsEmpty()const{return !value;} };
struct ItemEffectEntry {uint32 SpellID; int TriggerType=1;};
struct Item {uint32 id; int level; bool broken=false; std::vector<ItemEffectEntry const*> effects;
 uint32 GetEntry()const{return id;} uint32 GetItemLevel(Player const*)const{return level;} bool IsBroken()const{return broken;}
 auto const& GetEffects()const{return effects;} };
struct Aura {uint32 id; Guid guid; Guid GetCastItemGUID()const{return guid;} uint32 GetId()const{return id;} };
struct AuraApplication {Aura* aura; Aura* GetBase()const{return aura;}};
struct Unit {virtual ~Unit()=default; std::map<int,AuraApplication*> auras; virtual Player const* ToPlayer()const{return nullptr;}
 auto const& GetAppliedAuras()const{return auras;} Aura const* GetAura(uint32 id)const{for(auto const& a:auras)if(a.second->aura->id==id)return a.second->aura;return nullptr;}
 bool HasAura(uint32 id)const{return GetAura(id)!=nullptr;}};
struct Player:Unit {std::map<int,Item*> items; std::map<int,Item*> guids; Player const* ToPlayer()const override{return this;}
 Item* GetItemByPos(int,int slot)const{auto i=items.find(slot);return i==items.end()?nullptr:i->second;}
 Item* GetItemByGuid(Guid guid)const{auto i=guids.find(guid.value);return i==guids.end()?nullptr:i->second;}};
struct SpellEffectInfo {int32 BasePoints=100; bool zero=false;
 int32 CalcValue(Unit const*,void const* =nullptr,Unit const* =nullptr,void const* =nullptr,uint32=0,int32 level=-1)const{return zero?0:level>0?level:BasePoints;}};
struct SpellInfo {SpellEffectInfo effect; SpellEffectInfo const* GetEffect(int)const{return &effect;}};
struct SpellMgr {std::map<uint32,SpellInfo> spells; SpellInfo const* GetSpellInfo(uint32 id)const{auto i=spells.find(id);return i==spells.end()?nullptr:&i->second;}} manager;
SpellMgr* sSpellMgr=&manager;
int32 SumCorruptionRankDummy(Unit const* owner, uint32 const* rankIds, uint8 rankCount,
    SpellEffIndex effectIndex, bool useCalc, int32 fallback, char const* /*logKey*/)
{
    if (!owner || !rankIds || !rankCount)
        return 0;

    int32 sum = 0;
    auto addRank = [&](uint32 rankId, Item const* item)
    {
        SpellInfo const* rank = sSpellMgr->GetSpellInfo(rankId);
        SpellEffectInfo const* effect = rank ? rank->GetEffect(effectIndex) : nullptr;
        int32 value = effect ? (useCalc
            ? effect->CalcValue(owner, nullptr, owner, nullptr, item ? item->GetEntry() : 0,
                item ? int32(item->GetItemLevel(owner->ToPlayer())) : -1)
            : effect->BasePoints) : 0;
        sum += value > 0 ? value : std::max(fallback, 0);
    };

    if (Player const* player = owner->ToPlayer())
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (!item || item->IsBroken())
                continue;
            for (uint8 i = 0; i < rankCount; ++i)
            {
                if (!rankIds[i])
                    continue;
                for (ItemEffectEntry const* itemEffect : item->GetEffects())
                    if (itemEffect && itemEffect->SpellID == rankIds[i]
                        && itemEffect->TriggerType == ITEM_SPELLTRIGGER_ON_EQUIP)
                    {
                        addRank(rankIds[i], item);
                        break;
                    }
            }
        }

    // A manually applied rank has no item GUID; stale item-backed auras
    // must not recreate effects after the corresponding item is removed.
    for (auto const& applied : owner->GetAppliedAuras())
    {
        Aura const* aura = applied.second->GetBase();
        if (!aura || !aura->GetCastItemGUID().IsEmpty())
            continue;
        for (uint8 i = 0; i < rankCount; ++i)
            if (rankIds[i] && aura->GetId() == rankIds[i])
            {
                addRank(rankIds[i], nullptr);
                break;
            }
    }
    return sum;
}

int main(){int failures=0; auto check=[&](std::string name,int got,int expected){std::cout<<name<<": "<<got<<" expected "<<expected<<"\n"; failures+=got!=expected;};
manager.spells[1]={};manager.spells[2]={}; uint32 ranks[]={1,2}; ItemEffectEntry e1{1},e2{2},wrong{1,2};
Item a{101,100,false,{&e1}},b{102,200,false,{&e1}},c{103,200,false,{&e2}};
Aura itemAura{1,{1}},mixedAura{2,{2}},manualAura{1,{0}}; AuraApplication app1{&itemAura},app2{&mixedAura},manualApp{&manualAura};
Player player;player.items={{0,&a},{1,&b}};player.guids={{1,&a},{2,&b}};player.auras={{0,&app1}};
auto sum=[&](int fallback=7){return SumCorruptionRankDummy(&player,ranks,2,0,true,fallback,"mock");};
check("same rank own item levels",sum(),300);
player.items[1]=&c;player.guids[2]=&c;player.auras[1]=&app2; check("mixed ranks",sum(),300);
player.items.clear();player.guids.clear();player.auras={{0,&app1}};check("removed item stale aura",sum(),0);
player.items={{0,&a}};player.guids={{1,&a}};a.broken=true;check("broken item",sum(),0);a.broken=false;
player.items.clear();player.guids.clear();player.auras={{0,&manualApp}};check("manual non-item aura",sum(),100);
player.items={{0,&a}};player.auras[1]=&app1;check("manual plus item source",sum(),200);
player.items.clear();player.auras.clear();check("no source no fallback",sum(55),0);
check("null owner",SumCorruptionRankDummy(nullptr,ranks,2,0,true,55,"mock"),0);
player.items={{0,&a},{1,&b}};player.auras={{0,&app1}};manager.spells[1].effect.zero=true;check("fallback per existing source",sum(),14);manager.spells[1].effect.zero=false;
a.effects={&wrong};player.items={{0,&a}};check("non equip trigger excluded",sum(),0);
return failures?1:0;}
