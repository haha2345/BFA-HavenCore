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
void CorruptionRankItemContext(Unit const* owner, uint32 rankId, uint32& itemId, int32& itemLevel)
{
    itemId = 0;
    itemLevel = -1;
    Player const* player = owner ? owner->ToPlayer() : nullptr;
    if (!player)
        return;

    Aura const* aura = player->GetAura(rankId);
    if (!aura || aura->GetCastItemGUID().IsEmpty())
        return;

    if (Item* item = player->GetItemByGuid(aura->GetCastItemGUID()))
    {
        itemId = item->GetEntry();
        itemLevel = int32(item->GetItemLevel(player));
    }
}
int32 SumCorruptionRankDummy(Unit const* owner, uint32 const* rankIds, uint8 rankCount,
    SpellEffIndex effectIndex, bool useCalc, int32 fallback, char const* logKey)
{
    int32 sum = 0;
    bool any = false;
    if (owner)
    {
        for (uint8 i = 0; i < rankCount; ++i)
        {
            if (!rankIds[i] || !owner->HasAura(rankIds[i]))
                continue;
            any = true;
            SpellInfo const* rank = sSpellMgr->GetSpellInfo(rankIds[i]);
            if (!rank)
                continue;
            SpellEffectInfo const* effect = rank->GetEffect(effectIndex);
            if (!effect)
                continue;
            int32 value = 0;
            if (useCalc)
            {
                uint32 itemId = 0;
                int32 itemLevel = -1;
                CorruptionRankItemContext(owner, rankIds[i], itemId, itemLevel);
                value = effect->CalcValue(owner, nullptr, owner, nullptr, itemId, itemLevel);
            }
            else
                value = effect->BasePoints;
            if (value > 0)
                sum += value;
        }
    }

    if (sum >= 1)
        return sum;

    if (!any)
    {
        if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(rankIds[0]))
            if (SpellEffectInfo const* effect = rank->GetEffect(effectIndex))
            {
                int32 value = useCalc ? effect->CalcValue(owner) : effect->BasePoints;
                if (value >= 1)
                    return value;
            }
    }

    static std::set<std::string> logged;
    if (logged.insert(logKey).second)
        TC_LOG_ERROR("scripts", "%s: rank dummy missing, using %d", logKey, fallback);
    return fallback;
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
