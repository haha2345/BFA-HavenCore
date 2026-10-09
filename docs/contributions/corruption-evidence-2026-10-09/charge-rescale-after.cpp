#include <algorithm>
#include <chrono>
#include <cstdint>
#include <deque>
#include <iostream>
#include <map>
#include <string>
#include <vector>
using uint32=uint32_t;using int32=int32_t;using int64=int64_t;using Clock=std::chrono::system_clock;
Clock::time_point at(int64 ms){return Clock::time_point(std::chrono::milliseconds(ms));}
int64 count(Clock::time_point v){return std::chrono::duration_cast<std::chrono::milliseconds>(v.time_since_epoch()).count();}
namespace GameTime{Clock::time_point now; Clock::time_point GetGameTimeSystemPoint(){return now;}}
struct SpellCategoryEntry{uint32 ID=1;};struct Store{SpellCategoryEntry entry;SpellCategoryEntry const* LookupEntry(uint32 id){return id==1?&entry:nullptr;}}sSpellCategoryStore;
struct ChargeEntry{Clock::time_point RechargeStart,RechargeEnd;};
struct SpellHistory{std::map<uint32,std::deque<ChargeEntry>> _categoryCharges;void ScaleChargeRecovery(uint32,int32,bool);
 void UpdateCharge(SpellCategoryEntry const* c){auto& q=_categoryCharges[c->ID];while(!q.empty()&&q.front().RechargeEnd<=GameTime::now)q.pop_front();}
 void ForceSendSpellCharge(SpellCategoryEntry const*){}
 void Consume(int64 duration){auto& q=_categoryCharges[1];auto start=q.empty()?GameTime::now:q.back().RechargeEnd;q.push_back({start,start+std::chrono::milliseconds(duration)});}};
void SpellHistory::ScaleChargeRecovery(uint32 chargeCategoryId, int32 pct, bool apply)
{
    if (pct <= 0)
        return;

    SpellCategoryEntry const* chargeCategoryEntry = sSpellCategoryStore.LookupEntry(chargeCategoryId);
    auto itr = _categoryCharges.find(chargeCategoryId);
    if (!chargeCategoryEntry || itr == _categoryCharges.end() || itr->second.empty())
        return;

    Clock::time_point now = GameTime::GetGameTimeSystemPoint();
    Clock::time_point nextStart = now;
    bool first = true;
    for (ChargeEntry& entry : itr->second)
    {
        if (entry.RechargeEnd <= now)
            continue;

        // Only the active segment has elapsed time. Queued charges retain
        // their complete segment duration and begin when the prior one ends.
        Clock::time_point oldStart = first ? now : entry.RechargeStart;
        int64 remaining = std::chrono::duration_cast<std::chrono::milliseconds>(entry.RechargeEnd - oldStart).count();
        int64 factor = int64(100) + pct;
        int64 scaled = apply ? (remaining * 100) / factor : (remaining * factor) / 100;
        entry.RechargeStart = nextStart;
        entry.RechargeEnd = nextStart + std::chrono::milliseconds(std::max<int64>(scaled, 0));
        nextStart = entry.RechargeEnd;
        first = false;
    }

    UpdateCharge(chargeCategoryEntry);
    ForceSendSpellCharge(chargeCategoryEntry);
}

int main(){int failures=0;auto check=[&](std::string name,SpellHistory const& h,std::initializer_list<int64> times){auto const& q=h._categoryCharges.at(1);std::vector<int64> got;for(auto const& e:q){got.push_back(count(e.RechargeStart));got.push_back(count(e.RechargeEnd));}bool pass=got==std::vector<int64>(times);std::cout<<name<<": "<<(pass?"PASS":"FAIL")<<" [";for(auto x:got)std::cout<<x<<",";std::cout<<"]\n";failures+=!pass;};
SpellHistory h;h._categoryCharges[1]={{at(0),at(10000)},{at(10000),at(20000)}};GameTime::now=at(5000);h.ScaleChargeRecovery(1,100,true);check("buff apply two charges",h,{5000,7500,7500,12500});
GameTime::now=at(6000);h.ScaleChargeRecovery(1,100,false);check("buff removal active and queued",h,{6000,9000,9000,19000});
h._categoryCharges[1]={{at(0),at(10000)},{at(10000),at(20000)}};GameTime::now=at(5000);h.ScaleChargeRecovery(1,100,true);h.Consume(5000);check("new consumed charge stays continuous",h,{5000,7500,7500,12500,12500,17500});
h._categoryCharges[1]={{at(0),at(10000)},{at(10000),at(20000)},{at(20000),at(30000)}};GameTime::now=at(12500);h.ScaleChargeRecovery(1,100,true);check("expired charge removed",h,{12500,16250,16250,21250});
h._categoryCharges[1]={{at(0),at(10000)}};GameTime::now=at(5000);h.ScaleChargeRecovery(1,100,true);check("single active charge",h,{5000,7500});
h._categoryCharges[1]={{at(0),at(10000)},{at(10000),at(20000)}};GameTime::now=at(5000);h.ScaleChargeRecovery(1,0,true);check("zero percent no change",h,{0,10000,10000,20000});
h.ScaleChargeRecovery(1,-1,true);check("negative percent no change",h,{0,10000,10000,20000});
return failures?1:0;}
