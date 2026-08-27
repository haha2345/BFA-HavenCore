/*
 * 2026 BFA-HavenCore
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * 8.3 corruption on-equip effects (ItemEffect), not CorruptionEffects.db2 negatives.
 *
 * Infinite Stars (35662):
 *   324889/90/91  腐蚀 - 无尽之星 1/2/3  (item wrapper)
 *   317257        hidden proc aura -> 317260
 *   317260        dummy selector (50 yd)
 *   317262        missile visual (in-game: .cast 317262 triggered)
 *   317265        stack aura on target; school damage BP is 0 so we fill it
 *   318274/487/488 rank 1/2/3 hidden drivers (dummy % of max(AP, SP))
 *
 * Damage uses 318274/487/488 effect 2 dummy (83/208/312). Item-level
 * average(item) from aura 285 is not wired yet.
 *
 * Twilight Devastation (35662):
 *   318276/477/478  rank 1/2/3 (Aura 285 LINKED_2 -> 317147, dummy 60/120/180)
 *   317147          hidden proc aura, RPPM 1 haste, 4s ICD, autos+abilities
 *   317155          beam (CREATE_AREATRIGGER 19034 -> template 2307, 4s)
 *   317159          shadow school damage, BP=0 so we fill maxHP * (dummy/10)%
 *
 * Official hitbox: 317155 CREATE_AREATRIGGER misc 19034 -> template 23070
 * (cylinder r=3, h=10), spline ~28 yd / 4s. Damage is OnUnitEnter -> 317159,
 * hits anything attackable in the path (pulls, like retail). 2020-02 hotfix:
 * max 10 targets, 6th-10th take half damage.
 *
 * Echoing Void (35662):
 *   318280/485/486  rank 1/2/3 (Aura 285 LINKED -> 317014, dummy 40/60/100)
 *   317014          hidden proc; 35662 ProcFlags=0 (hotfix), ICD 700ms
 *   317020          stacks on the player (max 99)
 *   317022          collapse periodic -> 317029 every 1s (shared with Hivemind)
 *   317029          shadow AoE BP=0, 15 yd; script fills maxHP * (dummy/100)%
 *
 * Twisted Appendage (35662):
 *   318481/482/483  rank 1/2/3 (Aura 285 LINKED -> 316815, dummy 21/75/142)
 *   316815          hidden proc, RPPM 1 no haste, ProcFlags 69908 (autos+abilities)
 *   316818          summon 162764 for 10s, radius 3
 *   316835          Mind Flay: shadow periodic, 10s / 1s, BP=0
 *
 * Void Ritual (35662):
 *   318286/479/480  rank 1/2/3 (Aura 285 LINKED -> 316814, dummy 14/33/63)
 *   316814          hidden proc, RPPM 1, yellow+heal+hostile+periodic+trap
 *   316823          The End Is Coming: 20s, max 20 stacks, MOD_RATING + periodic
 *
 * Racing Pulse (35662):
 *   318266/492/496  rank 1/2/3 (Aura 285 LINKED -> 318220, dummy 546/728/1275)
 *   318220          hidden proc, RPPM 5, white+yellow+heal+hostile+periodic+trap
 *   318227          haste rating buff, 4s, no stacks, DBC BP=0 so we fill Dummy
 *
 * Honed Mind (35662):
 *   318269/494/498  rank 1/2/3 (Aura 285 LINKED -> 318214, dummy 392/523/915)
 *   318214          hidden proc, RPPM 3, white+yellow+heal+hostile+periodic+trap
 *   318216          mastery rating buff, 10s, no stacks, DBC BP=0 so we fill Dummy
 *
 * Deadly Momentum (35662):
 *   318268/493/497  rank 1/2/3 (Aura 285 LINKED -> 318218, dummy 31/41/72)
 *   318218          hidden proc, RPPM 5; DBC mask is wide so C++ keeps crits only
 *   318219          crit rating buff, 30s, max 5 stacks, DBC BP=0 so we fill Dummy
 *                   (engine multiplies MOD_RATING by stacks — do not multiply here)
 *
 * Surging Vitality (35662):
 *   318270/495/499  rank 1/2/3 (Aura 285 LINKED -> 318212)
 *                   Base was hotfixed to 0; rating is Scaled 343/458/801
 *   318212          hidden proc, RPPM 2, TAKEN melee/spell/periodic/heal
 *   318211          vers rating buff, 20s, no stacks, DBC BP=0 so we fill Scaled
 *
 * Gushing Wound (35662):
 *   318272          rank 1 (Aura 285 LINKED -> 318179). Coefficient is ilvl, P5
 *   318179          hidden proc, RPPM 4 haste, yellow melee/ranged + hostile spells
 *   318187          target shadow bleed, 7s / 1s, BP=0; tick = Dummy13% of max(AP,SP)
 *
 * Glimpse of Clarity (35662):
 *   318239          item wrapper (Aura 285 LINKED -> 315574)
 *   315574          hidden proc, RPPM 2, Dummy 3s / 1 next spell
 *   315573          15s buff, Dummy 3. Next class CD is trimmed; then consume a stack.
 *                   315573 has no ProcFlags — trim lives on PlayerScript, not OnProc.
 *
 * Ineffable Truth (35662):
 *   318303/484      rank 1/2 (Aura 285 LINKED -> 316799, dummy 30/50)
 *   316799          hidden proc, RPPM 1, yellow+heal+hostile (no white)
 *   316801          10s buff. Aura 143/173 are NYI — fill Dummy, then scale
 *                   remaining CDs on Apply/Remove and new CDs on cooldown start.
 *                   Rate is 100/(100+Dummy); never tick CDs every frame.
 *
 * Grasping Tendrils (CorruptionEffects, MinCorruption 1):
 *   315175          taken proc (RPPM 1). Do not compare corruption thresholds here.
 *   315176          5s snare. Amount = min(effectiveCorruption+10, 99).
 *                   99 cap is the 2020-02 hotfix whitelist, not a DBC field.
 *
 * Eye of Corruption (CorruptionEffects, MinCorruption 20):
 *   315169          class-ability proc. EFFECT_0 TriggerSpell from DBC (do not guess).
 *                   EFFECT_1 Dummy 2 = pulse period seconds. 315270 is the companion pet — skip it.
 *   Summon/damage IDs and creature entry come from SpellInfo at runtime; leave
 *   pack summonEntries empty until in-game CLEU fills them.
 *
 * Grand Delusions (CorruptionEffects, MinCorruption 40):
 *   315184          taken proc (RPPM 1). Do not compare corruption thresholds.
 *                   313301 is the cloak extra — never bind it here.
 *   Summon/damage IDs and creature entry come from SpellInfo at runtime; leave
 *   pack summonEntries empty until in-game lookup/CLEU fills them.
 *   Contact uses melee reach (unit body). No raycast. Visibility is all-visible
 *   until a core-supported "self + same-aura" filter exists.
 *
 * Cascading Disaster (CorruptionEffects, MinCorruption 60):
 *   315857          aura presence only. On Thing-from-Beyond contact, fire the
 *                   tendril and eye *trigger* paths (CastGraspingTendrils /
 *                   CastEyeOfCorruption). Do not re-apply 315175/315169.
 */

#include "AreaTrigger.h"
#include "AreaTriggerAI.h"
#include "Chat.h"
#include "Log.h"
#include "StringFormat.h"
#include "Item.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellHistory.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <cmath>
#include <memory>
#include <set>
#include <vector>

enum InfiniteStarsSpells
{
    SPELL_CORRUPTION_INFINITE_STARS_1 = 324889,
    SPELL_CORRUPTION_INFINITE_STARS_2 = 324890,
    SPELL_CORRUPTION_INFINITE_STARS_3 = 324891,
    SPELL_INFINITE_STARS_HIDDEN_PROC  = 317257,
    SPELL_INFINITE_STARS_SELECTOR     = 317260,
    SPELL_INFINITE_STARS_MISSILE      = 317262,
    SPELL_INFINITE_STARS_DAMAGE       = 317265,
    SPELL_INFINITE_STARS_RANK_1       = 318274,
    SPELL_INFINITE_STARS_RANK_2       = 318487,
    SPELL_INFINITE_STARS_RANK_3       = 318488
};

enum TwilightDevastationSpells
{
    SPELL_TWILIGHT_DEVASTATION_RANK_1 = 318276,
    SPELL_TWILIGHT_DEVASTATION_RANK_2 = 318477,
    SPELL_TWILIGHT_DEVASTATION_RANK_3 = 318478,
    SPELL_TWILIGHT_PROC               = 317147,
    SPELL_TWILIGHT_BEAM               = 317155,
    SPELL_TWILIGHT_DAMAGE             = 317159
};

enum EchoingVoidSpells
{
    SPELL_ECHOING_VOID_RANK_1   = 318280,
    SPELL_ECHOING_VOID_RANK_2   = 318485,
    SPELL_ECHOING_VOID_RANK_3   = 318486,
    SPELL_ECHOING_VOID_PROC     = 317014,
    SPELL_ECHOING_VOID_STACKS   = 317020,
    SPELL_ECHOING_VOID_COLLAPSE = 317022,
    SPELL_ECHOING_VOID_DAMAGE   = 317029
};

enum TwistedAppendageSpells
{
    SPELL_TWISTED_APPENDAGE_RANK_1 = 318481,
    SPELL_TWISTED_APPENDAGE_RANK_2 = 318482,
    SPELL_TWISTED_APPENDAGE_RANK_3 = 318483,
    SPELL_TWISTED_APPENDAGE_PROC   = 316815,
    SPELL_TWISTED_APPENDAGE_SUMMON = 316818,
    SPELL_TWISTED_APPENDAGE_FLAY   = 316835,
    NPC_TWISTED_APPENDAGE          = 162764
};

enum VoidRitualSpells
{
    SPELL_VOID_RITUAL_RANK_1     = 318286,
    SPELL_VOID_RITUAL_RANK_2     = 318479,
    SPELL_VOID_RITUAL_RANK_3     = 318480,
    SPELL_VOID_RITUAL_PROC       = 316814,
    SPELL_VOID_RITUAL_END_COMING = 316823
};

enum StrikethroughSpells
{
    SPELL_STRIKETHROUGH_RANK_1 = 315277,
    SPELL_STRIKETHROUGH_RANK_2 = 315281,
    SPELL_STRIKETHROUGH_RANK_3 = 315282,
    SPELL_STRIKETHROUGH_HIDDEN = 320249
};

enum RacingPulseSpells
{
    SPELL_RACING_PULSE_RANK_1 = 318266,
    SPELL_RACING_PULSE_RANK_2 = 318492,
    SPELL_RACING_PULSE_RANK_3 = 318496,
    SPELL_RACING_PULSE_PROC   = 318220,
    SPELL_RACING_PULSE_BUFF   = 318227
};

enum HonedMindSpells
{
    SPELL_HONED_MIND_RANK_1 = 318269,
    SPELL_HONED_MIND_RANK_2 = 318494,
    SPELL_HONED_MIND_RANK_3 = 318498,
    SPELL_HONED_MIND_PROC   = 318214,
    SPELL_HONED_MIND_BUFF   = 318216
};

enum DeadlyMomentumSpells
{
    SPELL_DEADLY_MOMENTUM_RANK_1 = 318268,
    SPELL_DEADLY_MOMENTUM_RANK_2 = 318493,
    SPELL_DEADLY_MOMENTUM_RANK_3 = 318497,
    SPELL_DEADLY_MOMENTUM_PROC   = 318218,
    SPELL_DEADLY_MOMENTUM_BUFF   = 318219
};

enum SurgingVitalitySpells
{
    SPELL_SURGING_VITALITY_RANK_1 = 318270,
    SPELL_SURGING_VITALITY_RANK_2 = 318495,
    SPELL_SURGING_VITALITY_RANK_3 = 318499,
    SPELL_SURGING_VITALITY_PROC   = 318212,
    SPELL_SURGING_VITALITY_BUFF   = 318211
};

enum GushingWoundSpells
{
    SPELL_GUSHING_WOUND_RANK = 318272,
    SPELL_GUSHING_WOUND_PROC = 318179,
    SPELL_GUSHING_WOUND_DOT  = 318187
};

enum GlimpseOfClaritySpells
{
    SPELL_GLIMPSE_ITEM = 318239,
    SPELL_GLIMPSE_PROC = 315574,
    SPELL_GLIMPSE_BUFF = 315573,
    SPELL_FLASH_OF_INSIGHT_ITEM = 318299,
    SPELL_FLASH_OF_INSIGHT_PROC = 316717
};

enum IneffableTruthSpells
{
    SPELL_INEFFABLE_TRUTH_RANK_1 = 318303,
    SPELL_INEFFABLE_TRUTH_RANK_2 = 318484,
    SPELL_INEFFABLE_TRUTH_PROC   = 316799,
    SPELL_INEFFABLE_TRUTH_BUFF   = 316801
};

enum GraspingTendrilsSpells
{
    SPELL_GRASPING_TENDRILS_PROC = 315175,
    SPELL_GRASPING_TENDRILS_SLOW = 315176
};

enum EyeOfCorruptionSpells
{
    SPELL_EYE_OF_CORRUPTION = 315169,
    SPELL_EYE_OF_CORRUPTION_PET = 315270 // companion pet, not the combat eye
};

enum GrandDelusionsSpells
{
    SPELL_GRAND_DELUSIONS = 315184,
    SPELL_THING_FROM_BEYOND_CLOAK = 313301 // cloak extra, not the 40-tier row
};

enum CascadingDisasterSpells
{
    SPELL_CASCADING_DISASTER = 315857
};

// Wowhead 25-30 yd; DBC 317155 has width 3, no length. TimeToTarget 4000 in spell_areatrigger.
constexpr float TWILIGHT_BEAM_RANGE_YD   = 28.0f;
constexpr uint32 TWILIGHT_BEAM_TRAVEL_MS = 4000;

// 2020-02 hotfix values, not in DBC: beam stops after 10 targets, 6th-10th take 50%.
constexpr uint32 TWILIGHT_BEAM_MAX_TARGETS      = 10;
constexpr uint32 TWILIGHT_BEAM_HALF_DAMAGE_FROM = 6;

// SimC bfa.echoing_void_collapse_chance. Not a DBC field — calibrate in-game if needed.
constexpr float ECHOING_VOID_COLLAPSE_CHANCE = 0.15f;
constexpr int32 ECHOING_VOID_RANK1_BP_FALLBACK = 40; // tooltip $s1/100 = 0.4% max HP
constexpr uint32 ECHOING_VOID_PERIOD_FALLBACK_MS = 1000;
constexpr int32 ECHOING_VOID_DURATION_SLACK_MS = 400;

constexpr int32 TWISTED_APPENDAGE_RANK1_PCT_FALLBACK = 21; // tooltip $s2/100 * max(AP, SP)

// DBC has ally count (2) but no radius. 8 yd is party-range "nearby".
constexpr float VOID_RITUAL_ALLY_RANGE_YD = 8.0f;
// SimC: solo RPPM *= 5/6. Not a DBC field — calibrate if in-game disagrees.
constexpr float VOID_RITUAL_SOLO_RPPM_MULT = 5.0f / 6.0f;
constexpr int32 VOID_RITUAL_RANK1_RATING_FALLBACK = 14;
constexpr uint32 VOID_RITUAL_ALLY_NEED_FALLBACK = 2;

// 320249 EFFECT_0 DBC BP is 0; fill crit-damage Dummy. Do not hardcode 2/3/4.
// Driver EFFECT_1 is a live SPELL_AURA_MOD_CRITICAL_HEALING_AMOUNT — leave 320249 heal at 0.
constexpr int32 STRIKETHROUGH_RANK1_CRIT_FALLBACK = 2;

// 318227 DBC BP is 0; fill rank Dummy. Do not hardcode 546 as the only value.
constexpr int32 RACING_PULSE_RANK1_RATING_FALLBACK = 546;

// 318216 DBC BP is 0; fill rank Dummy. Do not hardcode 392 as the only value.
constexpr int32 HONED_MIND_RANK1_RATING_FALLBACK = 392;

// 318219 DBC BP is 0; fill per-stack Dummy. Engine multiplies by stacks.
constexpr int32 DEADLY_MOMENTUM_RANK1_RATING_FALLBACK = 31;

// Driver Base was hotfixed to 0. Rank-1 dump Scaled is 343. Do not use Icy Veins 312.
constexpr int32 SURGING_VITALITY_RANK1_RATING_FALLBACK = 343;

// 318187 EFFECT_1 Dummy is 13 after hotfix (was 10). Per-tick %, not divided by 7 ticks.
constexpr int32 GUSHING_WOUND_TICK_PCT_FALLBACK = 13;

// 315573 / 315574 Dummy is 3 seconds. Do not hardcode 3000 as the only value.
constexpr int32 GLIMPSE_TRIM_MS_FALLBACK = 3000;

// 316801 DBC BP is 50 on both effects. Strength is the driver Dummy (30/50).
constexpr int32 INEFFABLE_TRUTH_RANK1_PCT_FALLBACK = 30;

// Wowhead / 清单: slow = effective corruption + 10, cap 99 (2020-02 hotfix).
constexpr int32 GRASPING_TENDRILS_BONUS_PCT = 10;
constexpr int32 GRASPING_TENDRILS_CAP_PCT = 99;

// Dummy 2 on 315169 is the pulse period. Duration 8s is Wowhead; prefer DBC duration.
constexpr uint32 EYE_PULSE_MS_FALLBACK = 2000;
constexpr uint32 EYE_DURATION_MS_FALLBACK = 8000;
constexpr float EYE_RADIUS_FALLBACK = 10.0f; // not DBC — log once if radius missing

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

// P5: sum Dummy from every worn rank (not highest). CalcValue picks up item-level scaling.
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

struct CorruptionDriverFamily
{
    uint32 ranks[3];
    uint8 rankCount;
    uint32 hiddenProc;
};

CorruptionDriverFamily const* FindCorruptionDriverFamily(uint32 spellId)
{
    static CorruptionDriverFamily const families[] =
    {
        { { SPELL_INFINITE_STARS_RANK_1, SPELL_INFINITE_STARS_RANK_2, SPELL_INFINITE_STARS_RANK_3 }, 3, SPELL_INFINITE_STARS_HIDDEN_PROC },
        { { SPELL_TWILIGHT_DEVASTATION_RANK_1, SPELL_TWILIGHT_DEVASTATION_RANK_2, SPELL_TWILIGHT_DEVASTATION_RANK_3 }, 3, SPELL_TWILIGHT_PROC },
        { { SPELL_ECHOING_VOID_RANK_1, SPELL_ECHOING_VOID_RANK_2, SPELL_ECHOING_VOID_RANK_3 }, 3, SPELL_ECHOING_VOID_PROC },
        { { SPELL_TWISTED_APPENDAGE_RANK_1, SPELL_TWISTED_APPENDAGE_RANK_2, SPELL_TWISTED_APPENDAGE_RANK_3 }, 3, SPELL_TWISTED_APPENDAGE_PROC },
        { { SPELL_VOID_RITUAL_RANK_1, SPELL_VOID_RITUAL_RANK_2, SPELL_VOID_RITUAL_RANK_3 }, 3, SPELL_VOID_RITUAL_PROC },
        { { SPELL_RACING_PULSE_RANK_1, SPELL_RACING_PULSE_RANK_2, SPELL_RACING_PULSE_RANK_3 }, 3, SPELL_RACING_PULSE_PROC },
        { { SPELL_HONED_MIND_RANK_1, SPELL_HONED_MIND_RANK_2, SPELL_HONED_MIND_RANK_3 }, 3, SPELL_HONED_MIND_PROC },
        { { SPELL_DEADLY_MOMENTUM_RANK_1, SPELL_DEADLY_MOMENTUM_RANK_2, SPELL_DEADLY_MOMENTUM_RANK_3 }, 3, SPELL_DEADLY_MOMENTUM_PROC },
        { { SPELL_SURGING_VITALITY_RANK_1, SPELL_SURGING_VITALITY_RANK_2, SPELL_SURGING_VITALITY_RANK_3 }, 3, SPELL_SURGING_VITALITY_PROC },
        { { SPELL_GUSHING_WOUND_RANK, 0, 0 }, 1, SPELL_GUSHING_WOUND_PROC },
        { { SPELL_GLIMPSE_ITEM, 0, 0 }, 1, SPELL_GLIMPSE_PROC },
        { { SPELL_INEFFABLE_TRUTH_RANK_1, SPELL_INEFFABLE_TRUTH_RANK_2, 0 }, 2, SPELL_INEFFABLE_TRUTH_PROC },
        { { SPELL_STRIKETHROUGH_RANK_1, SPELL_STRIKETHROUGH_RANK_2, SPELL_STRIKETHROUGH_RANK_3 }, 3, SPELL_STRIKETHROUGH_HIDDEN },
    };

    for (CorruptionDriverFamily const& family : families)
        for (uint8 i = 0; i < family.rankCount; ++i)
            if (family.ranks[i] == spellId)
                return &family;
    return nullptr;
}

void SyncCorruptionHiddenProc(Unit* owner, CorruptionDriverFamily const& family)
{
    if (!owner)
        return;

    bool any = false;
    for (uint8 i = 0; i < family.rankCount; ++i)
        if (family.ranks[i] && owner->HasAura(family.ranks[i]))
            any = true;

    if (any)
    {
        if (!owner->HasAura(family.hiddenProc))
            owner->CastSpell(owner, family.hiddenProc, true);
    }
    else
        owner->RemoveAurasDueToSpell(family.hiddenProc);
}

uint32 InfiniteStarsWrapperRank(uint32 wrapperId)
{
    switch (wrapperId)
    {
        case SPELL_CORRUPTION_INFINITE_STARS_3:
            return SPELL_INFINITE_STARS_RANK_3;
        case SPELL_CORRUPTION_INFINITE_STARS_2:
            return SPELL_INFINITE_STARS_RANK_2;
        case SPELL_CORRUPTION_INFINITE_STARS_1:
            return SPELL_INFINITE_STARS_RANK_1;
        default:
            return 0;
    }
}

namespace
{
// 35662 Spell dump fallbacks if GetEffect is missing.
constexpr int32 INFINITE_STARS_VULN_PCT_FALLBACK = 25;
constexpr float INFINITE_STARS_RANGE_FALLBACK    = 50.0f;
constexpr int32 INFINITE_STARS_RANK1_PCT_FALLBACK = 83;

uint32 InfiniteStarsRankSpell(Unit const* caster)
{
    if (caster->HasAura(SPELL_INFINITE_STARS_RANK_3) || caster->HasAura(SPELL_CORRUPTION_INFINITE_STARS_3))
        return SPELL_INFINITE_STARS_RANK_3;
    if (caster->HasAura(SPELL_INFINITE_STARS_RANK_2) || caster->HasAura(SPELL_CORRUPTION_INFINITE_STARS_2))
        return SPELL_INFINITE_STARS_RANK_2;
    return SPELL_INFINITE_STARS_RANK_1;
}

int32 InfiniteStarsVulnPct()
{
    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_INFINITE_STARS_DAMAGE))
        if (SpellEffectInfo const* effect = info->GetEffect(EFFECT_2))
            return effect->BasePoints;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "InfiniteStars: 317265 EFFECT_2 missing, using vuln %d", INFINITE_STARS_VULN_PCT_FALLBACK);
    }
    return INFINITE_STARS_VULN_PCT_FALLBACK;
}

float InfiniteStarsSelectRange()
{
    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_INFINITE_STARS_SELECTOR))
        if (SpellEffectInfo const* effect = info->GetEffect(EFFECT_0))
        {
            float radius = effect->CalcRadius();
            if (radius > 0.0f)
                return radius;
        }
    return INFINITE_STARS_RANGE_FALLBACK;
}

int32 InfiniteStarsBaseDamage(Unit const* caster)
{
    float ap = std::max(caster->GetTotalAttackPowerValue(BASE_ATTACK), caster->GetTotalAttackPowerValue(RANGED_ATTACK));
    float sp = float(caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE));
    uint32 const ranks[] = { SPELL_INFINITE_STARS_RANK_1, SPELL_INFINITE_STARS_RANK_2, SPELL_INFINITE_STARS_RANK_3 };
    int32 pct = SumCorruptionRankDummy(caster, ranks, 3, EFFECT_1, true,
        INFINITE_STARS_RANK1_PCT_FALLBACK, "InfiniteStars");

    int32 damage = int32(std::max(ap, sp) * (float(pct) / 100.0f));
    return damage < 1 ? 1 : damage;
}

// Ignore GCD / current cast / cost so a slam can still drop a star. Not FULL_DEBUG_MASK
// (that includes IGNORE_TARGET_CHECK and CAST_DIRECTLY).
TriggerCastFlags InfiniteStarsCastFlags()
{
    return TriggerCastFlags(
        TRIGGERED_IGNORE_GCD |
        TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD |
        TRIGGERED_IGNORE_POWER_AND_REAGENT_COST |
        TRIGGERED_IGNORE_CAST_IN_PROGRESS |
        TRIGGERED_IGNORE_CASTER_AURASTATE |
        TRIGGERED_IGNORE_SET_FACING |
        TRIGGERED_DONT_REPORT_CAST_ERROR |
        TRIGGERED_DISALLOW_PROC_EVENTS);
}

TriggerCastFlags TwilightDamageCastFlags()
{
    return TriggerCastFlags(uint32(InfiniteStarsCastFlags()) | uint32(TRIGGERED_IGNORE_TARGET_CHECK));
}

// Same-faction owner must still take the contact hit (four-piece keeps owner faction).
TriggerCastFlags DelusionHitCastFlags()
{
    return TriggerCastFlags(uint32(InfiniteStarsCastFlags()) | uint32(TRIGGERED_IGNORE_TARGET_CHECK));
}

void LabNotify(Unit* caster, char const* type, std::string const& kv)
{
    if (!caster || !type)
        return;

    Player* player = caster->ToPlayer();
    if (!player || !player->IsGameMaster() || !player->GetSession())
        return;

    if (kv.empty())
        ChatHandler(player->GetSession()).PSendSysMessage("[HavenLab] %s", type);
    else
        ChatHandler(player->GetSession()).PSendSysMessage("[HavenLab] %s %s", type, kv.c_str());
}

class InfiniteStarImpactEvent : public BasicEvent
{
public:
    InfiniteStarImpactEvent(ObjectGuid casterGuid, ObjectGuid targetGuid)
        : _casterGuid(casterGuid), _targetGuid(targetGuid) { }

    bool Execute(uint64 /*time*/, uint32 /*diff*/) override
    {
        // FindUnit() is world-wide and only reliable for players. The dummy is a
        // Creature: resolve it on the caster's map.
        Unit* caster = ObjectAccessor::FindPlayer(_casterGuid);
        if (!caster)
            caster = ObjectAccessor::FindUnit(_casterGuid);
        if (!caster)
            return true;

        Unit* target = ObjectAccessor::GetUnit(*caster, _targetGuid);
        if (!target || !target->IsAlive())
            return true;

        caster->CastSpell(target, SPELL_INFINITE_STARS_DAMAGE, InfiniteStarsCastFlags());
        return true;
    }

private:
    ObjectGuid _casterGuid;
    ObjectGuid _targetGuid;
};

void CastInfiniteStar(Unit* caster, Unit* target)
{
    if (!caster || !target || !target->IsAlive() || target == caster)
        return;

    if (caster->GetSpellHistory()->HasCooldown(SPELL_INFINITE_STARS_MISSILE))
        return;

    SpellInfo const* missile = sSpellMgr->GetSpellInfo(SPELL_INFINITE_STARS_MISSILE);
    uint32 visual = missile ? missile->GetSpellVisual(caster) : 0;
    float delay = (missile && missile->Speed > 0.0f) ? missile->Speed : 1.0f;

    // One visual path: DEST_DEST (87) CastSpell at the target's feet.
    bool ok = false;
    if (missile)
        ok = caster->CastSpell(target->GetPosition(), SPELL_INFINITE_STARS_MISSILE, InfiniteStarsCastFlags());

    TC_LOG_INFO("scripts", "InfiniteStars visual=%u speed=%.3f delay=%.3f missileCast=%u dest=%s",
        visual, missile ? missile->Speed : -1.f, delay, uint32(ok), target->GetName().c_str());
    LabNotify(caster, "STAR_VISUAL", Trinity::StringFormat(
        "spell=%u visual=%u delay=%.2f missile=%u target=%s",
        SPELL_INFINITE_STARS_MISSILE, visual, delay, ok ? 1u : 0u, target->GetName().c_str()));

    // Not a DBC value: stops 317257 and 317260 from each dropping a star.
    caster->GetSpellHistory()->AddCooldown(SPELL_INFINITE_STARS_MISSILE, 0, Milliseconds(1500));
    caster->m_Events.AddEvent(new InfiniteStarImpactEvent(caster->GetGUID(), target->GetGUID()),
        caster->m_Events.CalculateTime(uint32(delay * 1000.0f)));
}

Unit* ResolveStarTarget(Unit* caster, ProcEventInfo& eventInfo)
{
    if (Unit* procTarget = eventInfo.GetProcTarget())
        if (procTarget->IsAlive() && procTarget != caster)
            return procTarget;

    if (Unit* actionTarget = eventInfo.GetActionTarget())
        if (actionTarget->IsAlive() && actionTarget != caster)
            return actionTarget;

    if (Unit* victim = caster->GetVictim())
        if (victim->IsAlive() && victim != caster)
            return victim;

    return caster->SelectNearbyTarget(nullptr, InfiniteStarsSelectRange());
}

constexpr int32 TWILIGHT_RANK1_BP_FALLBACK = 60; // tooltip $s1/10 = 6% max HP

uint32 TwilightRankSpell(Unit const* caster)
{
    if (caster->HasAura(SPELL_TWILIGHT_DEVASTATION_RANK_3))
        return SPELL_TWILIGHT_DEVASTATION_RANK_3;
    if (caster->HasAura(SPELL_TWILIGHT_DEVASTATION_RANK_2))
        return SPELL_TWILIGHT_DEVASTATION_RANK_2;
    return SPELL_TWILIGHT_DEVASTATION_RANK_1;
}

float TwilightHealthPct(Unit const* caster)
{
    uint32 const ranks[] = { SPELL_TWILIGHT_DEVASTATION_RANK_1, SPELL_TWILIGHT_DEVASTATION_RANK_2, SPELL_TWILIGHT_DEVASTATION_RANK_3 };
    int32 bp = SumCorruptionRankDummy(caster, ranks, 3, EFFECT_0, true,
        TWILIGHT_RANK1_BP_FALLBACK, "TwilightDevastation");
    // DBC stores 60/120/180; tooltip is $s1/10 percent of health.
    return float(bp) / 10.0f / 100.0f;
}

void NotifyTwilightVisual(Unit* caster, uint32 visual, uint32 hits, int32 damage, bool beamOk)
{
    LabNotify(caster, "TWILIGHT_VISUAL", Trinity::StringFormat(
        "spell=%u visual=%u hits=%u damage=%d beam=%u",
        SPELL_TWILIGHT_BEAM, visual, hits, damage, beamOk ? 1u : 0u));
}

void NotifyTwilightHit(Unit* caster, Unit* target, uint32 hitIndex, int32 damage)
{
    if (!target)
        return;

    LabNotify(caster, "TWILIGHT_HIT", Trinity::StringFormat(
        "#%u target=%s damage=%d", hitIndex, target->GetName().c_str(), damage));
}

void CastTwilightDevastation(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    SpellInfo const* beamInfo = sSpellMgr->GetSpellInfo(SPELL_TWILIGHT_BEAM);
    uint32 visual = beamInfo ? beamInfo->GetSpellVisual(caster) : 0;
    int32 baseDamage = int32(float(caster->GetMaxHealth()) * TwilightHealthPct(caster));
    if (baseDamage < 1)
        baseDamage = 1;

    int32 duration = beamInfo ? beamInfo->CalcDuration(caster) : 0;
    if (duration <= 0)
        duration = int32(TWILIGHT_BEAM_TRAVEL_MS);

    uint32 miscId = 19034;
    if (beamInfo)
        if (SpellEffectInfo const* effect = beamInfo->GetEffect(EFFECT_0))
            if (effect->MiscValue)
                miscId = uint32(effect->MiscValue);

    // SpellGo plays visual 93766. CREATE_AREATRIGGER is prevented in the SpellScript
    // so we spawn exactly one AT (Haven's dest-HIT path often skipped the effect).
    bool beamOk = caster->CastSpell(caster->GetPosition(), SPELL_TWILIGHT_BEAM, InfiniteStarsCastFlags());

    // Damage lives in at_twilight_devastation::OnUnitEnter, driven by the AT's own
    // spline position (spell_areatrigger_splines 19034: 0 -> 28 yd over 4s).
    if (caster->GetAreaTriggers(SPELL_TWILIGHT_BEAM).empty())
        AreaTrigger::CreateAreaTrigger(miscId, caster, nullptr, beamInfo, *caster, duration, visual);

    NotifyTwilightVisual(caster, visual, 0, baseDamage, beamOk);
}

TriggerCastFlags EchoingVoidCastFlags()
{
    return InfiniteStarsCastFlags();
}

uint32 EchoingVoidRankSpell(Unit const* caster)
{
    if (caster->HasAura(SPELL_ECHOING_VOID_RANK_3))
        return SPELL_ECHOING_VOID_RANK_3;
    if (caster->HasAura(SPELL_ECHOING_VOID_RANK_2))
        return SPELL_ECHOING_VOID_RANK_2;
    return SPELL_ECHOING_VOID_RANK_1;
}

float EchoingVoidHealthPct(Unit const* caster)
{
    uint32 const ranks[] = { SPELL_ECHOING_VOID_RANK_1, SPELL_ECHOING_VOID_RANK_2, SPELL_ECHOING_VOID_RANK_3 };
    int32 bp = SumCorruptionRankDummy(caster, ranks, 3, EFFECT_0, true,
        ECHOING_VOID_RANK1_BP_FALLBACK, "EchoingVoid");
    // DBC stores 40/60/100; tooltip is $s1/100 percent of health (rank 1 = 0.4%).
    return float(bp) / 100.0f / 100.0f;
}

uint32 EchoingVoidPeriodMs()
{
    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_ECHOING_VOID_COLLAPSE))
        if (SpellEffectInfo const* effect = info->GetEffect(EFFECT_0))
            if (effect->ApplyAuraPeriod)
                return effect->ApplyAuraPeriod;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "EchoingVoid: 317022 period missing, using %u ms",
            ECHOING_VOID_PERIOD_FALLBACK_MS);
    }
    return ECHOING_VOID_PERIOD_FALLBACK_MS;
}

// Player Echoing Void casts 317022 on self. Hivemind puts 317022 on players from the boss.
bool EchoingVoidPlayerOwnsCollapse(Unit const* unit)
{
    if (!unit || !unit->HasAura(SPELL_ECHOING_VOID_PROC))
        return false;
    Aura const* collapse = unit->GetAura(SPELL_ECHOING_VOID_COLLAPSE);
    return collapse && collapse->GetCasterGUID() == unit->GetGUID();
}

void NotifyEchoStack(Unit* caster, uint32 stacks)
{
    LabNotify(caster, "ECHO_STACK", Trinity::StringFormat("stacks=%u", stacks));
}

void NotifyEchoCollapse(Unit* caster, uint32 stacks)
{
    LabNotify(caster, "ECHO_COLLAPSE", Trinity::StringFormat("stacks=%u", stacks));
}

void NotifyEchoTick(Unit* caster, uint32 remain)
{
    LabNotify(caster, "ECHO_TICK", Trinity::StringFormat("remain=%u", remain));
}

void StartEchoingVoidCollapse(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    uint32 stacks = 1;
    if (Aura const* stackAura = caster->GetAura(SPELL_ECHOING_VOID_STACKS))
        stacks = stackAura->GetStackAmount();
    if (stacks < 1)
        stacks = 1;

    NotifyEchoCollapse(caster, stacks);
    caster->CastSpell(caster, SPELL_ECHOING_VOID_COLLAPSE, EchoingVoidCastFlags());
}

void HandleEchoingVoidProc(Unit* caster, ProcEventInfo& eventInfo)
{
    if (!caster || !caster->IsAlive())
        return;

    // 2020-01-27 hotfix: only spells with a GCD stack. Autos / no-GCD trinkets do not.
    Spell const* procSpell = eventInfo.GetProcSpell();
    if (!procSpell || !procSpell->GetSpellInfo() || procSpell->GetSpellInfo()->StartRecoveryTime == 0)
        return;

    if (caster->HasAura(SPELL_ECHOING_VOID_COLLAPSE))
        return;

    if (caster->GetAura(SPELL_ECHOING_VOID_STACKS) && roll_chance_f(ECHOING_VOID_COLLAPSE_CHANCE * 100.0f))
    {
        StartEchoingVoidCollapse(caster);
        return;
    }

    caster->CastSpell(caster, SPELL_ECHOING_VOID_STACKS, EchoingVoidCastFlags());
    uint32 stacks = 1;
    if (Aura const* stackAura = caster->GetAura(SPELL_ECHOING_VOID_STACKS))
        stacks = stackAura->GetStackAmount();
    NotifyEchoStack(caster, stacks);
}

uint32 TwistedAppendageRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_TWISTED_APPENDAGE_RANK_3))
        return SPELL_TWISTED_APPENDAGE_RANK_3;
    if (owner->HasAura(SPELL_TWISTED_APPENDAGE_RANK_2))
        return SPELL_TWISTED_APPENDAGE_RANK_2;
    return SPELL_TWISTED_APPENDAGE_RANK_1;
}

int32 TwistedAppendageTickDamage(Unit const* owner)
{
    float ap = std::max(owner->GetTotalAttackPowerValue(BASE_ATTACK), owner->GetTotalAttackPowerValue(RANGED_ATTACK));
    float sp = float(owner->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
    uint32 const ranks[] = { SPELL_TWISTED_APPENDAGE_RANK_1, SPELL_TWISTED_APPENDAGE_RANK_2, SPELL_TWISTED_APPENDAGE_RANK_3 };
    int32 pct = SumCorruptionRankDummy(owner, ranks, 3, EFFECT_1, true,
        TWISTED_APPENDAGE_RANK1_PCT_FALLBACK, "TwistedAppendage");

    int32 damage = int32(std::max(ap, sp) * (float(pct) / 100.0f));
    return damage < 1 ? 1 : damage;
}

// Aura caster is the player (originalCaster) so ticks can crit and CLEU is
// player-to-creature. Fall back to the tentacle's owner if that is missing.
Unit* TwistedAppendageOwner(Unit* caster)
{
    if (!caster)
        return nullptr;
    if (Unit* owner = caster->GetOwner())
        return owner;
    return caster;
}

Unit* ResolveTentacleTarget(Unit* owner)
{
    if (Unit* victim = owner->GetVictim())
        if (victim->IsAlive() && victim != owner)
            return victim;

    if (Player* player = owner->ToPlayer())
        if (Unit* selected = player->GetSelectedUnit())
            if (selected->IsAlive() && selected != owner)
                if (owner->_IsValidAttackTarget(selected, sSpellMgr->GetSpellInfo(SPELL_TWISTED_APPENDAGE_FLAY)))
                    return selected;

    return owner->SelectNearbyTarget(nullptr, 50.0f);
}

void CastTwistedAppendage(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    bool ok = caster->CastSpell(caster, SPELL_TWISTED_APPENDAGE_SUMMON, InfiniteStarsCastFlags());
    Unit* target = ResolveTentacleTarget(caster);
    LabNotify(caster, "TENTACLE_SPAWN", Trinity::StringFormat(
        "summon=%u target=%s ok=%u",
        SPELL_TWISTED_APPENDAGE_SUMMON,
        target ? target->GetName().c_str() : "none",
        ok ? 1u : 0u));
}

// Channel 316835: keep CASTING so UpdateAI does not recast every tick.
TriggerCastFlags TwistedAppendageFlayFlags()
{
    return TriggerCastFlags(
        TRIGGERED_IGNORE_GCD |
        TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD |
        TRIGGERED_IGNORE_POWER_AND_REAGENT_COST |
        TRIGGERED_DONT_REPORT_CAST_ERROR |
        TRIGGERED_DISALLOW_PROC_EVENTS);
}

uint32 VoidRitualRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_VOID_RITUAL_RANK_3))
        return SPELL_VOID_RITUAL_RANK_3;
    if (owner->HasAura(SPELL_VOID_RITUAL_RANK_2))
        return SPELL_VOID_RITUAL_RANK_2;
    return SPELL_VOID_RITUAL_RANK_1;
}

int32 VoidRitualRatingPerStack(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_VOID_RITUAL_RANK_1, SPELL_VOID_RITUAL_RANK_2, SPELL_VOID_RITUAL_RANK_3 };
    return SumCorruptionRankDummy(owner, ranks, 3, EFFECT_0, true,
        VOID_RITUAL_RANK1_RATING_FALLBACK, "VoidRitual");
}

uint32 VoidRitualAllyNeed(Unit const* owner)
{
    if (SpellInfo const* proc = sSpellMgr->GetSpellInfo(SPELL_VOID_RITUAL_PROC))
        if (SpellEffectInfo const* effect = proc->GetEffect(EFFECT_2))
            if (effect->BasePoints > 0)
                return uint32(effect->BasePoints);

    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(VoidRitualRankSpell(owner)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_2))
            if (effect->BasePoints > 0)
                return uint32(effect->BasePoints);

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "VoidRitual: ally-need Dummy missing, using %u",
            VOID_RITUAL_ALLY_NEED_FALLBACK);
    }
    return VOID_RITUAL_ALLY_NEED_FALLBACK;
}

uint32 VoidRitualNearbyAllies(Unit* caster)
{
    if (!caster)
        return 0;

    // Grid search already drops other phases; keep an explicit IsInPhase
    // so a later scan helper cannot silently count phased-out allies.
    std::vector<Player*> players;
    caster->GetPlayerListInGrid(players, VOID_RITUAL_ALLY_RANGE_YD);

    uint32 allies = 0;
    for (Player* player : players)
    {
        if (!player || player == caster || !player->IsAlive())
            continue;
        if (!caster->IsInPhase(player))
            continue;
        if (!caster->IsFriendlyTo(player))
            continue;
        if (!player->HasAura(SPELL_VOID_RITUAL_PROC))
            continue;
        ++allies;
    }
    return allies;
}

void NotifyVoidRitualTick(Unit* owner, uint32 stacks, int32 rating)
{
    LabNotify(owner, "RITUAL_TICK", Trinity::StringFormat("stacks=%u rating=%d", stacks, rating));
}

void CastVoidRitual(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    if (caster->HasAura(SPELL_VOID_RITUAL_END_COMING))
    {
        LabNotify(caster, "RITUAL_PROC", "skipped=refresh");
        return;
    }

    uint32 allies = VoidRitualNearbyAllies(caster);
    bool increased = allies >= VoidRitualAllyNeed(caster);
    if (!increased && !roll_chance_f(VOID_RITUAL_SOLO_RPPM_MULT * 100.0f))
    {
        LabNotify(caster, "RITUAL_PROC", Trinity::StringFormat(
            "skipped=solo allies=%u", allies));
        return;
    }

    bool ok = caster->CastSpell(caster, SPELL_VOID_RITUAL_END_COMING, InfiniteStarsCastFlags());
    LabNotify(caster, "RITUAL_PROC", Trinity::StringFormat(
        "allies=%u increased=%u ok=%u",
        allies, increased ? 1u : 0u, ok ? 1u : 0u));
}

uint32 StrikethroughRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_STRIKETHROUGH_RANK_3))
        return SPELL_STRIKETHROUGH_RANK_3;
    if (owner->HasAura(SPELL_STRIKETHROUGH_RANK_2))
        return SPELL_STRIKETHROUGH_RANK_2;
    return SPELL_STRIKETHROUGH_RANK_1;
}

int32 StrikethroughCritDamagePct(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_STRIKETHROUGH_RANK_1, SPELL_STRIKETHROUGH_RANK_2, SPELL_STRIKETHROUGH_RANK_3 };
    return SumCorruptionRankDummy(owner, ranks, 3, EFFECT_0, true,
        STRIKETHROUGH_RANK1_CRIT_FALLBACK, "Strikethrough");
}

uint32 RacingPulseRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_RACING_PULSE_RANK_3))
        return SPELL_RACING_PULSE_RANK_3;
    if (owner->HasAura(SPELL_RACING_PULSE_RANK_2))
        return SPELL_RACING_PULSE_RANK_2;
    return SPELL_RACING_PULSE_RANK_1;
}

int32 RacingPulseRating(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_RACING_PULSE_RANK_1, SPELL_RACING_PULSE_RANK_2, SPELL_RACING_PULSE_RANK_3 };
    return SumCorruptionRankDummy(owner, ranks, 3, EFFECT_0, true,
        RACING_PULSE_RANK1_RATING_FALLBACK, "RacingPulse");
}

void CastRacingPulse(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    int32 rating = RacingPulseRating(caster);
    bool ok = caster->CastSpell(caster, SPELL_RACING_PULSE_BUFF, InfiniteStarsCastFlags());
    LabNotify(caster, "PULSE_PROC", Trinity::StringFormat(
        "rating=%d ok=%u", rating, ok ? 1u : 0u));
}

uint32 HonedMindRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_HONED_MIND_RANK_3))
        return SPELL_HONED_MIND_RANK_3;
    if (owner->HasAura(SPELL_HONED_MIND_RANK_2))
        return SPELL_HONED_MIND_RANK_2;
    return SPELL_HONED_MIND_RANK_1;
}

int32 HonedMindRating(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_HONED_MIND_RANK_1, SPELL_HONED_MIND_RANK_2, SPELL_HONED_MIND_RANK_3 };
    return SumCorruptionRankDummy(owner, ranks, 3, EFFECT_0, true,
        HONED_MIND_RANK1_RATING_FALLBACK, "HonedMind");
}

void CastHonedMind(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    int32 rating = HonedMindRating(caster);
    bool ok = caster->CastSpell(caster, SPELL_HONED_MIND_BUFF, InfiniteStarsCastFlags());
    LabNotify(caster, "MIND_PROC", Trinity::StringFormat(
        "rating=%d ok=%u", rating, ok ? 1u : 0u));
}

uint32 DeadlyMomentumRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_DEADLY_MOMENTUM_RANK_3))
        return SPELL_DEADLY_MOMENTUM_RANK_3;
    if (owner->HasAura(SPELL_DEADLY_MOMENTUM_RANK_2))
        return SPELL_DEADLY_MOMENTUM_RANK_2;
    return SPELL_DEADLY_MOMENTUM_RANK_1;
}

int32 DeadlyMomentumRatingPerStack(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_DEADLY_MOMENTUM_RANK_1, SPELL_DEADLY_MOMENTUM_RANK_2, SPELL_DEADLY_MOMENTUM_RANK_3 };
    return SumCorruptionRankDummy(owner, ranks, 3, EFFECT_0, true,
        DEADLY_MOMENTUM_RANK1_RATING_FALLBACK, "DeadlyMomentum");
}

void CastDeadlyMomentum(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    bool ok = caster->CastSpell(caster, SPELL_DEADLY_MOMENTUM_BUFF, InfiniteStarsCastFlags());
    uint32 stacks = 1;
    if (Aura const* aura = caster->GetAura(SPELL_DEADLY_MOMENTUM_BUFF))
        stacks = aura->GetStackAmount();
    if (stacks < 1)
        stacks = 1;
    int32 rating = DeadlyMomentumRatingPerStack(caster) * int32(stacks);
    LabNotify(caster, "MOMENTUM_PROC", Trinity::StringFormat(
        "stacks=%u rating=%d ok=%u", stacks, rating, ok ? 1u : 0u));
}

uint32 SurgingVitalityRankSpell(Unit const* owner)
{
    if (owner->HasAura(SPELL_SURGING_VITALITY_RANK_3))
        return SPELL_SURGING_VITALITY_RANK_3;
    if (owner->HasAura(SPELL_SURGING_VITALITY_RANK_2))
        return SPELL_SURGING_VITALITY_RANK_2;
    return SPELL_SURGING_VITALITY_RANK_1;
}

int32 SurgingVitalityRating(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_SURGING_VITALITY_RANK_1, SPELL_SURGING_VITALITY_RANK_2, SPELL_SURGING_VITALITY_RANK_3 };
    return SumCorruptionRankDummy(owner, ranks, 3, EFFECT_0, true,
        SURGING_VITALITY_RANK1_RATING_FALLBACK, "SurgingVitality");
}

void CastSurgingVitality(Unit* caster)
{
    if (!caster || !caster->IsAlive())
        return;

    int32 rating = SurgingVitalityRating(caster);
    bool ok = caster->CastSpell(caster, SPELL_SURGING_VITALITY_BUFF, InfiniteStarsCastFlags());
    LabNotify(caster, "VITAL_PROC", Trinity::StringFormat(
        "rating=%d ok=%u", rating, ok ? 1u : 0u));
}

int32 GushingWoundTickPct()
{
    if (SpellInfo const* dot = sSpellMgr->GetSpellInfo(SPELL_GUSHING_WOUND_DOT))
        if (SpellEffectInfo const* effect = dot->GetEffect(EFFECT_1))
            if (effect->BasePoints >= 1)
                return effect->BasePoints;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "GushingWound: 318187 EFFECT_1 missing, using %d%%",
            GUSHING_WOUND_TICK_PCT_FALLBACK);
    }
    return GUSHING_WOUND_TICK_PCT_FALLBACK;
}

int32 GushingWoundTickDamage(Unit const* owner)
{
    float ap = std::max(owner->GetTotalAttackPowerValue(BASE_ATTACK), owner->GetTotalAttackPowerValue(RANGED_ATTACK));
    float sp = float(owner->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
    int32 damage = int32(std::max(ap, sp) * (float(GushingWoundTickPct()) / 100.0f));
    return damage < 1 ? 1 : damage;
}

Unit* ResolveGushingWoundTarget(Unit* caster, ProcEventInfo& eventInfo)
{
    if (Unit* procTarget = eventInfo.GetProcTarget())
        if (procTarget->IsAlive() && procTarget != caster)
            return procTarget;

    if (Unit* actionTarget = eventInfo.GetActionTarget())
        if (actionTarget->IsAlive() && actionTarget != caster)
            return actionTarget;

    if (Unit* victim = caster->GetVictim())
        if (victim->IsAlive() && victim != caster)
            return victim;

    return caster->SelectNearbyTarget(nullptr, 50.0f);
}

void CastGushingWound(Unit* caster, Unit* target)
{
    if (!caster || !caster->IsAlive() || !target || !target->IsAlive() || target == caster)
        return;
    if (!caster->_IsValidAttackTarget(target, sSpellMgr->GetSpellInfo(SPELL_GUSHING_WOUND_DOT)))
        return;

    bool ok = caster->CastSpell(target, SPELL_GUSHING_WOUND_DOT, InfiniteStarsCastFlags());
    LabNotify(caster, "WOUND_PROC", Trinity::StringFormat(
        "target=%s ok=%u", target->GetName().c_str(), ok ? 1u : 0u));
}

int32 GlimpseTrimMs(Unit const* /*owner*/)
{
    if (SpellInfo const* buff = sSpellMgr->GetSpellInfo(SPELL_GLIMPSE_BUFF))
        if (SpellEffectInfo const* effect = buff->GetEffect(EFFECT_0))
            if (effect->BasePoints >= 1)
                return effect->BasePoints * IN_MILLISECONDS;

    if (SpellInfo const* proc = sSpellMgr->GetSpellInfo(SPELL_GLIMPSE_PROC))
        if (SpellEffectInfo const* effect = proc->GetEffect(EFFECT_0))
            if (effect->BasePoints >= 1)
                return effect->BasePoints * IN_MILLISECONDS;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "GlimpseOfClarity: Dummy missing, using trim %d ms",
            GLIMPSE_TRIM_MS_FALLBACK);
    }
    return GLIMPSE_TRIM_MS_FALLBACK;
}

bool IsGlimpseExcludedSpell(uint32 id)
{
    switch (id)
    {
        case SPELL_INFINITE_STARS_SELECTOR:
        case SPELL_INFINITE_STARS_MISSILE:
        case SPELL_INFINITE_STARS_DAMAGE:
        case SPELL_TWILIGHT_BEAM:
        case SPELL_TWILIGHT_DAMAGE:
        case SPELL_ECHOING_VOID_COLLAPSE:
        case SPELL_ECHOING_VOID_DAMAGE:
        case SPELL_TWISTED_APPENDAGE_SUMMON:
        case SPELL_TWISTED_APPENDAGE_FLAY:
        case SPELL_GUSHING_WOUND_DOT:
        case SPELL_GLIMPSE_ITEM:
        case SPELL_GLIMPSE_PROC:
        case SPELL_GLIMPSE_BUFF:
        case SPELL_FLASH_OF_INSIGHT_ITEM:
        case SPELL_FLASH_OF_INSIGHT_PROC:
        case SPELL_INEFFABLE_TRUTH_RANK_1:
        case SPELL_INEFFABLE_TRUTH_RANK_2:
        case SPELL_INEFFABLE_TRUTH_PROC:
        case SPELL_INEFFABLE_TRUTH_BUFF:
        case SPELL_GRASPING_TENDRILS_PROC:
        case SPELL_GRASPING_TENDRILS_SLOW:
        case SPELL_EYE_OF_CORRUPTION:
        case SPELL_EYE_OF_CORRUPTION_PET:
        case SPELL_GRAND_DELUSIONS:
        case SPELL_THING_FROM_BEYOND_CLOAK:
        case SPELL_CASCADING_DISASTER:
            return true;
        default:
            return false;
    }
}

bool IsIneffableTruthOwnSpell(uint32 id)
{
    switch (id)
    {
        case SPELL_INEFFABLE_TRUTH_RANK_1:
        case SPELL_INEFFABLE_TRUTH_RANK_2:
        case SPELL_INEFFABLE_TRUTH_PROC:
        case SPELL_INEFFABLE_TRUTH_BUFF:
            return true;
        default:
            return false;
    }
}

int32 IneffableTruthPct(Unit const* owner)
{
    uint32 const ranks[] = { SPELL_INEFFABLE_TRUTH_RANK_1, SPELL_INEFFABLE_TRUTH_RANK_2 };
    return SumCorruptionRankDummy(owner, ranks, 2, EFFECT_0, true,
        INEFFABLE_TRUTH_RANK1_PCT_FALLBACK, "IneffableTruth");
}

void ApplyIneffableTruthRate(int32& ms, int32 pct)
{
    if (ms > 0 && pct > 0)
        ms = int32(int64(ms) * 100 / (100 + pct));
}

void ScaleExistingCharges(Player* player, int32 pct, bool apply);

void ScaleExistingCooldowns(Player* player, int32 pct, bool apply)
{
    if (!player || pct <= 0)
        return;

    SpellHistory* history = player->GetSpellHistory();
    if (!history)
        return;

    for (PlayerSpellMap::value_type const& kv : player->GetSpellMap())
    {
        if (!kv.second || kv.second->state == PLAYERSPELL_REMOVED)
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(kv.first);
        if (!info || IsIneffableTruthOwnSpell(info->Id) || IsGlimpseExcludedSpell(info->Id))
            continue;

        uint32 remain = history->GetRemainingCooldown(info);
        if (!remain || remain > uint32(DAY * IN_MILLISECONDS))
            continue;

        int64 scaled = apply
            ? (int64(remain) * 100) / (100 + pct)
            : (int64(remain) * (100 + pct)) / 100;
        int32 delta = int32(scaled - int64(remain));
        if (delta)
            history->ModifyCooldown(info->Id, delta);
    }

    ScaleExistingCharges(player, pct, apply);
}

bool IneffableTruthScalesChargeCategory(Player const* player, uint32 chargeCategoryId)
{
    if (!player || !chargeCategoryId)
        return false;

    for (PlayerSpellMap::value_type const& kv : player->GetSpellMap())
    {
        if (!kv.second || kv.second->state == PLAYERSPELL_REMOVED)
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(kv.first);
        if (!info || info->ChargeCategoryId != chargeCategoryId)
            continue;
        if (info->IsPassive() || IsIneffableTruthOwnSpell(info->Id) || IsGlimpseExcludedSpell(info->Id))
            continue;
        return true;
    }

    return false;
}

void ScaleExistingCharges(Player* player, int32 pct, bool apply)
{
    if (!player || pct <= 0)
        return;

    SpellHistory* history = player->GetSpellHistory();
    if (!history)
        return;

    std::set<uint32> seen;
    for (PlayerSpellMap::value_type const& kv : player->GetSpellMap())
    {
        if (!kv.second || kv.second->state == PLAYERSPELL_REMOVED)
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(kv.first);
        if (!info || !info->ChargeCategoryId || !seen.insert(info->ChargeCategoryId).second)
            continue;
        if (!IneffableTruthScalesChargeCategory(player, info->ChargeCategoryId))
            continue;

        history->ScaleChargeRecovery(info->ChargeCategoryId, pct, apply);
    }
}

float EffectiveCorruptionRating(Player const* player)
{
    if (!player)
        return 0.0f;
    return player->GetRatingBonusValue(CR_CORRUPTION) - player->GetRatingBonusValue(CR_CORRUPTION_RESISTANCE);
}

int32 GraspingTendrilsBonusPct()
{
    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_GRASPING_TENDRILS_PROC))
        if (SpellEffectInfo const* effect = info->GetEffect(EFFECT_0))
            if (effect->BasePoints >= GRASPING_TENDRILS_BONUS_PCT)
                return effect->BasePoints;

    return GRASPING_TENDRILS_BONUS_PCT;
}

int32 GraspingTendrilsSlowPct(Player const* player)
{
    int32 pct = int32(EffectiveCorruptionRating(player)) + GraspingTendrilsBonusPct();
    if (pct < 0)
        pct = 0;
    if (pct > GRASPING_TENDRILS_CAP_PCT)
        pct = GRASPING_TENDRILS_CAP_PCT;
    return pct;
}

void CastGraspingTendrils(Unit* owner)
{
    Player* player = owner ? owner->ToPlayer() : nullptr;
    if (!player || !player->IsAlive())
        return;

    int32 pct = GraspingTendrilsSlowPct(player);
    bool ok = player->CastCustomSpell(SPELL_GRASPING_TENDRILS_SLOW, SPELLVALUE_BASE_POINT0, pct, player, InfiniteStarsCastFlags());
    LabNotify(player, "TENDRIL_SLOW", Trinity::StringFormat(
        "pct=%d corr=%.0f ok=%u", pct, EffectiveCorruptionRating(player), ok ? 1u : 0u));
}

struct EyeChain
{
    uint32 triggerSpell = 0;
    uint32 summonEntry = 0;
    uint32 damageSpell = 0;
    float radius = 0.0f;
    uint32 pulseMs = EYE_PULSE_MS_FALLBACK;
    uint32 durationMs = EYE_DURATION_MS_FALLBACK;
};

void InspectSpellForEye(SpellInfo const* info, EyeChain& chain, uint8 depth = 0)
{
    if (!info || depth > 3)
        return;

    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
    {
        SpellEffectInfo const* effect = info->GetEffect(SpellEffIndex(i));
        if (!effect)
            continue;

        if (effect->Effect == SPELL_EFFECT_SUMMON && effect->MiscValue > 0)
            chain.summonEntry = uint32(effect->MiscValue);

        if (effect->Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
            chain.damageSpell = info->Id;
        if (effect->Effect == SPELL_EFFECT_APPLY_AURA && effect->ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE)
            chain.damageSpell = info->Id;

        float radius = effect->CalcRadius();
        if (radius > chain.radius)
            chain.radius = radius;

        if (effect->TriggerSpell && effect->TriggerSpell != SPELL_EYE_OF_CORRUPTION_PET
            && effect->TriggerSpell != SPELL_EYE_OF_CORRUPTION)
            InspectSpellForEye(sSpellMgr->GetSpellInfo(effect->TriggerSpell), chain, depth + 1);
    }
}

EyeChain const& ResolveEyeChain()
{
    static EyeChain chain;
    static bool loaded = false;
    if (loaded)
        return chain;
    loaded = true;

    SpellInfo const* driver = sSpellMgr->GetSpellInfo(SPELL_EYE_OF_CORRUPTION);
    if (!driver)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "EyeOfCorruption: 315169 missing");
        }
        return chain;
    }

    if (SpellEffectInfo const* triggerEff = driver->GetEffect(EFFECT_0))
        if (triggerEff->TriggerSpell && triggerEff->TriggerSpell != SPELL_EYE_OF_CORRUPTION_PET)
            chain.triggerSpell = triggerEff->TriggerSpell;

    if (SpellEffectInfo const* dummy = driver->GetEffect(EFFECT_1))
        if (dummy->BasePoints >= 1)
            chain.pulseMs = uint32(dummy->BasePoints) * IN_MILLISECONDS;

    if (chain.triggerSpell)
    {
        if (SpellInfo const* trigger = sSpellMgr->GetSpellInfo(chain.triggerSpell))
        {
            int32 duration = trigger->GetDuration();
            if (duration > 0)
                chain.durationMs = uint32(duration);
            InspectSpellForEye(trigger, chain);
        }
    }

    if (chain.radius <= 0.0f)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "EyeOfCorruption: DBC radius missing, using %.1f yd", EYE_RADIUS_FALLBACK);
        }
        chain.radius = EYE_RADIUS_FALLBACK;
    }

    return chain;
}

struct npc_eye_of_corruption : public Scripted_NoMovementAI
{
    explicit npc_eye_of_corruption(Creature* creature) : Scripted_NoMovementAI(creature) { }

    void BindOwner(Unit* owner)
    {
        if (!owner)
        {
            me->DespawnOrUnsummon();
            return;
        }

        _ownerGuid = owner->GetGUID();
        me->SetFaction(owner->getFaction());
        me->SetLevel(owner->getLevel());
        me->SetReactState(REACT_PASSIVE);
        me->AddUnitState(UNIT_STATE_ROOT);
        _timer = 0;
        _elapsed = 0;
    }

    void IsSummonedBy(Unit* summoner) override
    {
        BindOwner(summoner);
    }

    void UpdateAI(uint32 diff) override
    {
        Unit* owner = ObjectAccessor::GetUnit(*me, _ownerGuid);
        if (!owner)
            owner = me->GetOwner();

        if (!owner || !owner->IsAlive() || !owner->HasAura(SPELL_EYE_OF_CORRUPTION))
        {
            me->DespawnOrUnsummon();
            return;
        }

        EyeChain const& chain = ResolveEyeChain();
        _elapsed += diff;
        if (_elapsed >= chain.durationMs)
        {
            me->DespawnOrUnsummon();
            return;
        }

        _timer += diff;
        if (_timer < chain.pulseMs)
            return;
        _timer = 0;

        bool inRange = owner->GetDistance(me) <= chain.radius;
        uint32 ok = 0;
        if (inRange && chain.damageSpell)
            ok = me->CastSpell(owner, chain.damageSpell, InfiniteStarsCastFlags(), nullptr, nullptr, owner->GetGUID()) ? 1u : 0u;

        LabNotify(owner, "EYE_PULSE", Trinity::StringFormat(
            "inrange=%u damage=%u ok=%u", inRange ? 1u : 0u, chain.damageSpell, ok));
    }

private:
    ObjectGuid _ownerGuid;
    uint32 _timer = 0;
    uint32 _elapsed = 0;
};

void BindEyeAI(Creature* eye, Unit* owner)
{
    if (!eye || !owner)
        return;
    eye->AIM_Initialize(new npc_eye_of_corruption(eye));
    if (npc_eye_of_corruption* ai = dynamic_cast<npc_eye_of_corruption*>(eye->AI()))
        ai->BindOwner(owner);
}

void CastEyeOfCorruption(Unit* owner)
{
    Player* player = owner ? owner->ToPlayer() : nullptr;
    if (!player || !player->IsAlive())
        return;

    EyeChain const& chain = ResolveEyeChain();
    if (!chain.triggerSpell)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "EyeOfCorruption: 315169 TriggerSpell missing");
        }
        LabNotify(player, "EYE_PROC", "trigger=0 entry=0 damage=0");
        return;
    }

    bool ok = player->CastSpell(player, chain.triggerSpell, InfiniteStarsCastFlags());
    Creature* eye = nullptr;
    if (chain.summonEntry)
        if (Creature* found = player->FindNearestCreature(chain.summonEntry, 20.0f))
            if (found->GetOwnerGUID() == player->GetGUID()
                || (found->ToTempSummon() && found->ToTempSummon()->GetSummonerGUID() == player->GetGUID()))
                eye = found;

    if (eye)
        BindEyeAI(eye, player);

    LabNotify(player, "EYE_PROC", Trinity::StringFormat(
        "trigger=%u entry=%u damage=%u radius=%.1f ok=%u",
        chain.triggerSpell, chain.summonEntry, chain.damageSpell, chain.radius, ok ? 1u : 0u));
}

void TryCascadingDisaster(Unit* owner)
{
    if (!owner || !owner->HasAura(SPELL_CASCADING_DISASTER))
        return;

    CastGraspingTendrils(owner);
    CastEyeOfCorruption(owner);
    LabNotify(owner, "CASCADE", "tendril=1 eye=1");
}

constexpr uint32 DELUSION_DURATION_MS_FALLBACK = 8000;

struct DelusionChain
{
    uint32 triggerSpell = 0;
    uint32 summonEntry = 0;
    uint32 damageSpell = 0;
    uint32 durationMs = DELUSION_DURATION_MS_FALLBACK;
};

void InspectDelusionSpell(SpellInfo const* info, DelusionChain& chain, uint8 depth = 0)
{
    if (!info || depth > 3 || info->Id == SPELL_THING_FROM_BEYOND_CLOAK)
        return;

    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
    {
        SpellEffectInfo const* effect = info->GetEffect(SpellEffIndex(i));
        if (!effect)
            continue;
        if (effect->Effect == SPELL_EFFECT_SUMMON && effect->MiscValue > 0)
            chain.summonEntry = uint32(effect->MiscValue);
        if (effect->Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
            chain.damageSpell = info->Id;
        if (effect->TriggerSpell && effect->TriggerSpell != SPELL_THING_FROM_BEYOND_CLOAK)
            InspectDelusionSpell(sSpellMgr->GetSpellInfo(effect->TriggerSpell), chain, depth + 1);
    }
}

DelusionChain const& ResolveDelusionChain()
{
    static DelusionChain chain;
    static bool loaded = false;
    if (loaded)
        return chain;
    loaded = true;

    SpellInfo const* driver = sSpellMgr->GetSpellInfo(SPELL_GRAND_DELUSIONS);
    if (!driver)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "GrandDelusions: 315184 missing");
        }
        return chain;
    }

    if (SpellEffectInfo const* triggerEff = driver->GetEffect(EFFECT_0))
        if (triggerEff->TriggerSpell && triggerEff->TriggerSpell != SPELL_THING_FROM_BEYOND_CLOAK)
            chain.triggerSpell = triggerEff->TriggerSpell;

    if (chain.triggerSpell)
    {
        if (SpellInfo const* trigger = sSpellMgr->GetSpellInfo(chain.triggerSpell))
        {
            int32 duration = trigger->GetDuration();
            if (duration > 0)
                chain.durationMs = uint32(duration);
            else
            {
                static bool logged = false;
                if (!logged)
                {
                    logged = true;
                    TC_LOG_ERROR("scripts", "GrandDelusions: trigger %u duration missing, using %u ms",
                        chain.triggerSpell, DELUSION_DURATION_MS_FALLBACK);
                }
            }
            InspectDelusionSpell(trigger, chain);
        }
    }

    if (!chain.summonEntry)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "GrandDelusions: summon MiscValue missing");
        }
    }
    if (!chain.damageSpell)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "GrandDelusions: school damage spell missing");
        }
    }

    return chain;
}

struct npc_thing_from_beyond : public ScriptedAI
{
    explicit npc_thing_from_beyond(Creature* creature) : ScriptedAI(creature) { }

    void BindOwner(Unit* owner)
    {
        if (!owner)
        {
            me->DespawnOrUnsummon();
            return;
        }

        _ownerGuid = owner->GetGUID();
        _hit = false;
        _elapsed = 0;
        me->SetFaction(owner->getFaction());
        me->SetLevel(owner->getLevel());
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveChase(owner);
    }

    void IsSummonedBy(Unit* summoner) override
    {
        BindOwner(summoner);
    }

    void UpdateAI(uint32 diff) override
    {
        Unit* owner = ObjectAccessor::GetUnit(*me, _ownerGuid);
        if (!owner)
            owner = me->GetOwner();

        if (!owner || !owner->IsAlive() || !owner->HasAura(SPELL_GRAND_DELUSIONS))
        {
            me->DespawnOrUnsummon();
            return;
        }

        DelusionChain const& chain = ResolveDelusionChain();
        _elapsed += diff;
        if (_elapsed >= chain.durationMs)
        {
            me->DespawnOrUnsummon();
            return;
        }

        if (_hit)
            return;

        if (!me->isMoving())
            me->GetMotionMaster()->MoveChase(owner);

        // Contact = unit body / melee reach. No raycast, no auto-swing.
        if (!me->IsWithinMeleeRange(owner))
            return;

        _hit = true;
        uint32 ok = 0;
        if (chain.damageSpell)
            ok = me->CastSpell(owner, chain.damageSpell, DelusionHitCastFlags(), nullptr, nullptr, owner->GetGUID()) ? 1u : 0u;

        LabNotify(owner, "DELUSION_HIT", Trinity::StringFormat(
            "entry=%u damage=%u ok=%u", me->GetEntry(), chain.damageSpell, ok));
        TryCascadingDisaster(owner);
        me->DespawnOrUnsummon();
    }

private:
    ObjectGuid _ownerGuid;
    bool _hit = false;
    uint32 _elapsed = 0;
};

void BindDelusionAI(Creature* thing, Unit* owner)
{
    if (!thing || !owner)
        return;
    thing->AIM_Initialize(new npc_thing_from_beyond(thing));
    if (npc_thing_from_beyond* ai = dynamic_cast<npc_thing_from_beyond*>(thing->AI()))
        ai->BindOwner(owner);
}

void CastGrandDelusions(Unit* owner)
{
    Player* player = owner ? owner->ToPlayer() : nullptr;
    if (!player || !player->IsAlive())
        return;

    DelusionChain const& chain = ResolveDelusionChain();
    if (!chain.triggerSpell)
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "GrandDelusions: 315184 TriggerSpell missing");
        }
        LabNotify(player, "DELUSION_PROC", "trigger=0 entry=0");
        return;
    }

    bool ok = player->CastSpell(player, chain.triggerSpell, InfiniteStarsCastFlags());
    Creature* thing = nullptr;
    if (chain.summonEntry)
    {
        for (Creature* found : player->FindNearestCreatures(chain.summonEntry, 30.0f))
        {
            if (!found)
                continue;
            if (found->GetOwnerGUID() == player->GetGUID()
                || (found->ToTempSummon() && found->ToTempSummon()->GetSummonerGUID() == player->GetGUID()))
            {
                thing = found;
                break;
            }
        }
    }

    if (thing)
        BindDelusionAI(thing, player);
    else
    {
        static bool logged = false;
        if (!logged)
        {
            logged = true;
            TC_LOG_ERROR("scripts", "GrandDelusions: summon not bound entry=%u trigger=%u",
                chain.summonEntry, chain.triggerSpell);
        }
    }

    LabNotify(player, "DELUSION_PROC", Trinity::StringFormat(
        "trigger=%u entry=%u damage=%u ok=%u",
        chain.triggerSpell, chain.summonEntry, chain.damageSpell, ok ? 1u : 0u));
}

void ConsumeGlimpseStack(Player* player)
{
    Aura* aura = player->GetAura(SPELL_GLIMPSE_BUFF);
    if (!aura)
        return;

    if (aura->GetStackAmount() <= 1)
        player->RemoveAurasDueToSpell(SPELL_GLIMPSE_BUFF);
    else
        aura->ModStackAmount(-1);
}

void TryGlimpseTrim(Player* player, Spell* spell)
{
    if (!player || !spell || !player->HasAura(SPELL_GLIMPSE_BUFF))
        return;

    SpellInfo const* info = spell->GetSpellInfo();
    if (!info || info->IsPassive() || spell->IsTriggered())
        return;
    if (!info->SpellFamilyName)
        return;
    if (!info->GetRecoveryTime() && !info->ChargeCategoryId)
        return;
    if (spell->m_CastItem || spell->m_castItemEntry)
        return;
    if (IsGlimpseExcludedSpell(info->Id))
        return;

    SpellHistory* history = player->GetSpellHistory();
    if (!history)
        return;

    int32 trim = GlimpseTrimMs(player);
    uint32 before = history->GetRemainingCooldown(info);
    if (info->ChargeCategoryId)
        history->ReduceChargeCooldown(info->ChargeCategoryId, uint32(trim));
    if (info->GetRecoveryTime() > 0 || before > 0)
        history->ModifyCooldown(info->Id, -trim);

    uint32 after = history->GetRemainingCooldown(info);
    ConsumeGlimpseStack(player);
    LabNotify(player, "CD_TRIM", Trinity::StringFormat(
        "spell=%u before=%u after=%u", info->Id, before, after));
}
}

// 324889/324890/324891 - wrapper has no aura. AfterCast applies the rank driver; family hook syncs 317257.
class spell_corruption_infinite_stars : public SpellScript
{
    PrepareSpellScript(spell_corruption_infinite_stars);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_INFINITE_STARS_RANK_1, SPELL_INFINITE_STARS_HIDDEN_PROC });
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        SpellInfo const* info = GetSpellInfo();
        if (!caster || !info)
            return;
        if (uint32 rank = InfiniteStarsWrapperRank(info->Id))
            caster->CastSpell(caster, rank, true, GetCastItem());
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_corruption_infinite_stars::HandleAfterCast);
    }
};

// Rank drivers (ItemEffect ON_EQUIP). Keep hidden proc up while any rank of the family remains.
class spell_corruption_rank_driver : public AuraScript
{
    PrepareAuraScript(spell_corruption_rank_driver);

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        if (Unit* owner = GetTarget())
            if (CorruptionDriverFamily const* family = FindCorruptionDriverFamily(GetId()))
                SyncCorruptionHiddenProc(owner, *family);
    }

    void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        if (Unit* owner = GetTarget())
            if (CorruptionDriverFamily const* family = FindCorruptionDriverFamily(GetId()))
                SyncCorruptionHiddenProc(owner, *family);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_corruption_rank_driver::HandleApply, EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_corruption_rank_driver::HandleRemove, EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

// 317257 - hidden proc aura
class spell_infinite_stars_proc : public AuraScript
{
    PrepareAuraScript(spell_infinite_stars_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_INFINITE_STARS_SELECTOR, SPELL_INFINITE_STARS_MISSILE, SPELL_INFINITE_STARS_DAMAGE });
    }

    void HandleProc(ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastInfiniteStar(caster, ResolveStarTarget(caster, eventInfo));
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_infinite_stars_proc::HandleProc);
    }
};

// 317260 - dummy selector (core may trigger this from 317257)
class spell_infinite_stars_selector : public SpellScript
{
    PrepareSpellScript(spell_infinite_stars_selector);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_INFINITE_STARS_MISSILE, SPELL_INFINITE_STARS_DAMAGE,
            SPELL_INFINITE_STARS_RANK_1, SPELL_INFINITE_STARS_RANK_2, SPELL_INFINITE_STARS_RANK_3 });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        Unit* target = GetHitUnit();
        if (!target || target == caster)
        {
            if (Unit* expl = GetExplTargetUnit())
                if (expl != caster)
                    target = expl;
        }
        if (!target || target == caster)
            target = caster->GetVictim();
        if (!target)
            target = caster->SelectNearbyTarget(nullptr, InfiniteStarsSelectRange());

        CastInfiniteStar(caster, target);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_infinite_stars_selector::HandleDummy, EFFECT_FIRST_FOUND, SPELL_EFFECT_DUMMY);
    }
};

// 317265 - dummy hit (DBC school damage BP is 0; stack aura still applies from effects)
class spell_infinite_stars_damage : public SpellScript
{
    PrepareSpellScript(spell_infinite_stars_damage);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_INFINITE_STARS_RANK_1, SPELL_INFINITE_STARS_RANK_2, SPELL_INFINITE_STARS_RANK_3 });
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        int32 damage = InfiniteStarsBaseDamage(caster);

        // 317265 applies its stack aura in the same hit. SimC multiplies with stacks *before* this star.
        int32 stacks = 0;
        if (Aura const* aura = target->GetAura(SPELL_INFINITE_STARS_DAMAGE, caster->GetGUID()))
            stacks = int32(aura->GetStackAmount());
        if (stacks > 0)
            --stacks;
        AddPct(damage, InfiniteStarsVulnPct() * stacks);

        // BP is 0; fill hit and let the school-damage effect deal it. DealDamage on top
        // double-dipped HP (twice the tooltip amount per star).
        SetHitDamage(damage);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_infinite_stars_damage::HandleHit);
    }
};

// 317147 - hidden proc (RPPM 1 haste, 4s ICD; DBC includes white hits)
class spell_twilight_devastation_proc : public AuraScript
{
    PrepareAuraScript(spell_twilight_devastation_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_TWILIGHT_BEAM, SPELL_TWILIGHT_DAMAGE,
            SPELL_TWILIGHT_DEVASTATION_RANK_1, SPELL_TWILIGHT_DEVASTATION_RANK_2, SPELL_TWILIGHT_DEVASTATION_RANK_3 });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        if (!caster)
            return;

        TC_LOG_INFO("scripts", "TwilightDevastation proc caster=%s", caster->GetName().c_str());
        CastTwilightDevastation(caster);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_twilight_devastation_proc::HandleProc);
    }
};

// 317159 - shadow damage BP is 0; script fills maxHP * (rank dummy/10)%
class spell_twilight_devastation_damage : public SpellScript
{
    PrepareSpellScript(spell_twilight_devastation_damage);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_TWILIGHT_DEVASTATION_RANK_1, SPELL_TWILIGHT_DEVASTATION_RANK_2, SPELL_TWILIGHT_DEVASTATION_RANK_3 });
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        // The AT passes the (possibly halved) amount via SPELLVALUE_BASE_POINT0; keep it.
        if (GetHitDamage() > 0)
            return;

        int32 damage = int32(float(caster->GetMaxHealth()) * TwilightHealthPct(caster));
        if (damage < 1)
            damage = 1;

        // BP is 0; fill hit and let the school-damage effect apply (crit/vers). Do not DealDamage
        // on top — that would double-dip HP.
        SetHitDamage(damage);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_twilight_devastation_damage::HandleHit);
    }
};

// 317155 - CREATE_AREATRIGGER 19034. Dest on the caster; the effect itself is spawned in
// CastTwilightDevastation (this core often never runs SPELL_EFFECT_HANDLE_HIT for it).
class spell_twilight_devastation_beam : public SpellScript
{
    PrepareSpellScript(spell_twilight_devastation_beam);

    void SetDest(SpellDestination& dest)
    {
        if (Unit* caster = GetCaster())
            dest.Relocate(*caster);
    }

    void PreventAT(SpellEffIndex /*effIndex*/)
    {
        PreventHitDefaultEffect(EFFECT_0);
    }

    void Register() override
    {
        OnDestinationTargetSelect += SpellDestinationTargetSelectFn(spell_twilight_devastation_beam::SetDest, EFFECT_0, TARGET_DEST_CASTER);
        OnDestinationTargetSelect += SpellDestinationTargetSelectFn(spell_twilight_devastation_beam::SetDest, EFFECT_0, TARGET_DEST_DEST_FRONT);
        OnEffectHit += SpellEffectFn(spell_twilight_devastation_beam::PreventAT, EFFECT_0, SPELL_EFFECT_CREATE_AREATRIGGER);
    }
};

// areatrigger_template 23070 (SpellMiscId 19034). Cylinder r=3 h=10 flies 28 yd / 4s; damage on enter.
// Hits anything attackable in the path (retail beam pulls idle mobs). 2020-02 hotfix:
// 6th-10th target take half damage, beam ends after the 10th.
struct at_twilight_devastation : AreaTriggerAI
{
    at_twilight_devastation(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger), _hitCount(0) { }

    void OnCreate() override
    {
        // Spline comes from spell_areatrigger_splines (19034: unique points 0..28 yd,
        // Catmullrom needs no duplicated endpoints on this core). Fallback if the DB row is gone.
        if (!at->HasSplines())
        {
            std::vector<Position> pts =
            {
                { 0.0f, 0.0f, 0.0f },
                { TWILIGHT_BEAM_RANGE_YD * 0.33f, 0.0f, 0.0f },
                { TWILIGHT_BEAM_RANGE_YD * 0.66f, 0.0f, 0.0f },
                { TWILIGHT_BEAM_RANGE_YD, 0.0f, 0.0f }
            };
            at->InitSplineOffsets(pts, TWILIGHT_BEAM_TRAVEL_MS);
        }
    }

    void OnUnitEnter(Unit* unit) override
    {
        Unit* caster = at->GetCaster();
        if (!caster || !unit || unit == caster || !unit->IsAlive())
            return;

        SpellInfo const* damageInfo = sSpellMgr->GetSpellInfo(SPELL_TWILIGHT_DAMAGE);
        if (!caster->_IsValidAttackTarget(unit, damageInfo))
            return;

        // Same-tick enters keep calling OnUnitEnter after Remove(); cap before any settle.
        if (_hitCount >= TWILIGHT_BEAM_MAX_TARGETS)
            return;

        // Each target is hit once per beam even if it re-enters the sphere.
        if (!_hitGuids.insert(unit->GetGUID()).second)
            return;

        ++_hitCount;

        int32 damage = int32(float(caster->GetMaxHealth()) * TwilightHealthPct(caster));
        if (_hitCount >= TWILIGHT_BEAM_HALF_DAMAGE_FROM)
            damage /= 2;
        if (damage < 1)
            damage = 1;

        caster->CastCustomSpell(SPELL_TWILIGHT_DAMAGE, SPELLVALUE_BASE_POINT0, damage, unit, TwilightDamageCastFlags());
        NotifyTwilightHit(caster, unit, _hitCount, damage);

        if (_hitCount >= TWILIGHT_BEAM_MAX_TARGETS)
            at->Remove();
    }

private:
    std::set<ObjectGuid> _hitGuids;
    uint32 _hitCount;
};

// 317014 - hidden proc. 35662 ProcFlags were hotfixed to 0; spell_proc restores 69904.
class spell_echoing_void_proc : public AuraScript
{
    PrepareAuraScript(spell_echoing_void_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_ECHOING_VOID_STACKS, SPELL_ECHOING_VOID_COLLAPSE, SPELL_ECHOING_VOID_DAMAGE,
            SPELL_ECHOING_VOID_RANK_1, SPELL_ECHOING_VOID_RANK_2, SPELL_ECHOING_VOID_RANK_3 });
    }

    void HandleProc(ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            HandleEchoingVoidProc(caster, eventInfo);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_echoing_void_proc::HandleProc);
    }
};

// 317022 - collapse periodic. Shared with Hivemind; only rewrite duration / first tick when the
// caster owns 317014 (player Echoing Void). Otherwise leave the boss aura alone.
class spell_echoing_void_collapse : public AuraScript
{
    PrepareAuraScript(spell_echoing_void_collapse);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_ECHOING_VOID_PROC, SPELL_ECHOING_VOID_STACKS, SPELL_ECHOING_VOID_DAMAGE });
    }

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(SPELL_ECHOING_VOID_PROC))
            return;

        uint32 stacks = 1;
        if (Aura const* stackAura = caster->GetAura(SPELL_ECHOING_VOID_STACKS))
            stacks = stackAura->GetStackAmount();
        if (stacks < 1)
            stacks = 1;

        uint32 period = EchoingVoidPeriodMs();
        int32 duration = int32(stacks * period + uint32(ECHOING_VOID_DURATION_SLACK_MS));
        SetMaxDuration(duration);
        SetDuration(duration);

        // Engine first tick is at +period unless START_PERIODIC_AT_APPLY. SimC pulses immediately.
        if (!GetSpellInfo()->HasAttribute(SPELL_ATTR5_START_PERIODIC_AT_APPLY))
            if (Unit* owner = GetTarget())
                owner->CastSpell(owner, SPELL_ECHOING_VOID_DAMAGE, EchoingVoidCastFlags());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_echoing_void_collapse::HandleApply, EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

// 317029 - shadow AoE, BP=0. Fill maxHP * (rank dummy/100)%. Decrement stacks once per cast
// (AfterCast, not OnHit — this is an AoE). Shared with Hivemind: only rewrite when the
// player owns both 317014 and a self-cast 317022.
class spell_echoing_void_damage : public SpellScript
{
    PrepareSpellScript(spell_echoing_void_damage);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_ECHOING_VOID_PROC, SPELL_ECHOING_VOID_STACKS, SPELL_ECHOING_VOID_COLLAPSE,
            SPELL_ECHOING_VOID_RANK_1, SPELL_ECHOING_VOID_RANK_2, SPELL_ECHOING_VOID_RANK_3 });
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        if (!EchoingVoidPlayerOwnsCollapse(caster))
            return;

        int32 damage = int32(float(caster->GetMaxHealth()) * EchoingVoidHealthPct(caster));
        if (damage < 1)
            damage = 1;

        SetHitDamage(damage);
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (!EchoingVoidPlayerOwnsCollapse(caster))
            return;

        uint32 remain = 0;
        if (Aura* stacks = caster->GetAura(SPELL_ECHOING_VOID_STACKS))
        {
            if (stacks->GetStackAmount() <= 1)
            {
                caster->RemoveAurasDueToSpell(SPELL_ECHOING_VOID_STACKS);
                caster->RemoveAurasDueToSpell(SPELL_ECHOING_VOID_COLLAPSE);
            }
            else
            {
                stacks->ModStackAmount(-1);
                remain = stacks->GetStackAmount();
            }
        }
        else
            caster->RemoveAurasDueToSpell(SPELL_ECHOING_VOID_COLLAPSE);

        NotifyEchoTick(caster, remain);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_echoing_void_damage::HandleHit);
        AfterCast += SpellCastFn(spell_echoing_void_damage::HandleAfterCast);
    }
};

// 316815 - hidden proc. DBC already has RPPM 1 and ProcFlags 69908 (autos+abilities).
class spell_twisted_appendage_proc : public AuraScript
{
    PrepareAuraScript(spell_twisted_appendage_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_TWISTED_APPENDAGE_SUMMON, SPELL_TWISTED_APPENDAGE_FLAY,
            SPELL_TWISTED_APPENDAGE_RANK_1, SPELL_TWISTED_APPENDAGE_RANK_2, SPELL_TWISTED_APPENDAGE_RANK_3 });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastTwistedAppendage(caster);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_twisted_appendage_proc::HandleProc);
    }
};

// 316835 - Mind Flay periodic, BP=0. Fill max(AP,SP)*(rank dummy/100) from the owner.
// Shared creature entry: no 316815 on the owner -> leave amount at 0.
// originalCaster is the player: ticks use player crit and player-to-creature CLEU.
class spell_twisted_appendage_flay : public AuraScript
{
    PrepareAuraScript(spell_twisted_appendage_flay);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_TWISTED_APPENDAGE_PROC,
            SPELL_TWISTED_APPENDAGE_RANK_1, SPELL_TWISTED_APPENDAGE_RANK_2, SPELL_TWISTED_APPENDAGE_RANK_3 });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes /*mode*/)
    {
        // Player originalCaster would haste the period/duration. Official tick is 1s / 10s.
        // DBC has no ATTR5_START_PERIODIC_AT_APPLY; first tick at +1s misses the 10th
        // when the 10s tentacle despawns. Mind Flay ticks on apply.
        if (SpellInfo const* info = GetSpellInfo())
        {
            int32 duration = info->GetDuration();
            if (duration > 0)
            {
                SetMaxDuration(duration);
                SetDuration(duration);
            }
        }

        if (AuraEffect* effect = const_cast<AuraEffect*>(aurEff))
        {
            effect->CalculatePeriodic(nullptr, false, false);
            effect->SetPeriodicTimer(0);
        }
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = false;

        Unit* owner = TwistedAppendageOwner(GetCaster());
        if (!owner || !owner->HasAura(SPELL_TWISTED_APPENDAGE_PROC))
            return;

        amount = TwistedAppendageTickDamage(owner);
    }

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        if (aurEff->GetAmount() <= 0)
            return;

        Unit* owner = TwistedAppendageOwner(GetCaster());
        if (!owner)
            return;

        LabNotify(owner, "TENTACLE_TICK", Trinity::StringFormat("damage=%d", aurEff->GetAmount()));
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_twisted_appendage_flay::HandleApply, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_twisted_appendage_flay::CalculateAmount, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_twisted_appendage_flay::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

// 162764 - Twisted Appendage. Only mind-flays when the owner wears 316815.
struct npc_twisted_appendage : public Scripted_NoMovementAI
{
    npc_twisted_appendage(Creature* creature) : Scripted_NoMovementAI(creature) { }

    void IsSummonedBy(Unit* summoner) override
    {
        if (!summoner || !summoner->HasAura(SPELL_TWISTED_APPENDAGE_PROC))
        {
            me->DespawnOrUnsummon();
            return;
        }

        me->SetFaction(summoner->getFaction());
        me->SetLevel(summoner->getLevel());
        me->SetReactState(REACT_PASSIVE);
        me->AddUnitState(UNIT_STATE_ROOT);

        Unit* target = ResolveTentacleTarget(summoner);
        _flayTarget = target ? target->GetGUID() : ObjectGuid::Empty;
        StartFlay(target);
    }

    void UpdateAI(uint32 /*diff*/) override
    {
        Unit* owner = me->GetOwner();
        if (!owner || !owner->IsAlive() || !owner->HasAura(SPELL_TWISTED_APPENDAGE_PROC))
        {
            if (me->IsSummon())
                me->DespawnOrUnsummon();
            return;
        }

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        Unit* target = ObjectAccessor::GetUnit(*me, _flayTarget);
        if (!target || !target->IsAlive())
        {
            target = ResolveTentacleTarget(owner);
            _flayTarget = target ? target->GetGUID() : ObjectGuid::Empty;
        }

        StartFlay(target);
    }

private:
    ObjectGuid _flayTarget;

    void StartFlay(Unit* target)
    {
        Unit* owner = me->GetOwner();
        if (!target || !owner || me->HasUnitState(UNIT_STATE_CASTING))
            return;
        if (target->HasAura(SPELL_TWISTED_APPENDAGE_FLAY, owner->GetGUID()))
            return;

        // melee=false: pull into combat, do not auto-swing.
        if (me->Attack(target, false))
            DoStartNoMovement(target);

        // originalCaster = owner: crit + player-to-creature CLEU. Channel stays on the tentacle.
        me->CastSpell(target, SPELL_TWISTED_APPENDAGE_FLAY, TwistedAppendageFlayFlags(), nullptr, nullptr, owner->GetGUID());
    }
};

// 316814 - hidden proc. DBC already has RPPM 1 and yellow/heal/hostile/periodic/trap flags.
class spell_void_ritual_proc : public AuraScript
{
    PrepareAuraScript(spell_void_ritual_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_VOID_RITUAL_END_COMING,
            SPELL_VOID_RITUAL_RANK_1, SPELL_VOID_RITUAL_RANK_2, SPELL_VOID_RITUAL_RANK_3 });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastVoidRitual(caster);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_void_ritual_proc::HandleProc);
    }
};

// 316823 - The End Is Coming. MOD_RATING amount = rank Dummy * stacks.
class spell_void_ritual_end_is_coming : public AuraScript
{
    PrepareAuraScript(spell_void_ritual_end_is_coming);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_VOID_RITUAL_PROC,
            SPELL_VOID_RITUAL_RANK_1, SPELL_VOID_RITUAL_RANK_2, SPELL_VOID_RITUAL_RANK_3 });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;

        Unit* owner = GetUnitOwner();
        if (!owner || !owner->HasAura(SPELL_VOID_RITUAL_PROC))
        {
            amount = 0;
            return;
        }

        uint32 stacks = GetAura() ? GetAura()->GetStackAmount() : 1;
        if (stacks < 1)
            stacks = 1;
        amount = VoidRitualRatingPerStack(owner) * int32(stacks);
    }

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* owner = GetUnitOwner();
        if (!owner || !owner->HasAura(SPELL_VOID_RITUAL_PROC))
            return;

        uint32 stacks = GetAura() ? GetAura()->GetStackAmount() : 1;
        NotifyVoidRitualTick(owner, stacks, VoidRitualRatingPerStack(owner) * int32(stacks));
    }

    void HandlePeriodic(AuraEffect const* /*aurEff*/)
    {
        Unit* owner = GetUnitOwner();
        Aura* aura = GetAura();
        if (!owner || !aura || !owner->HasAura(SPELL_VOID_RITUAL_PROC))
            return;

        uint32 maxStacks = aura->GetMaxStackAmount();
        if (!maxStacks)
            maxStacks = 20;
        uint32 before = aura->GetStackAmount();
        // refresh=false: official window is 20s total. Default ModStackAmount
        // resets duration, which turned a 20s ramp into ~40s (this log: 15s→56s).
        if (before < maxStacks)
            aura->ModStackAmount(1, AURA_REMOVE_BY_DEFAULT, false, false);

        uint32 stacks = aura->GetStackAmount();
        int32 rating = VoidRitualRatingPerStack(owner) * int32(stacks);
        if (AuraEffect* ratingEff = aura->GetEffect(EFFECT_0))
            ratingEff->ChangeAmount(rating);

        if (stacks != before)
            NotifyVoidRitualTick(owner, stacks, rating);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_void_ritual_end_is_coming::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_RATING);
        AfterEffectApply += AuraEffectApplyFn(spell_void_ritual_end_is_coming::HandleApply, EFFECT_0, SPELL_AURA_MOD_RATING, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_void_ritual_end_is_coming::HandlePeriodic, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// 315277/81/82 - driver. Aura 285 Trigger 320249; apply hidden if the trigger did not.
class spell_strikethrough_driver : public AuraScript
{
    PrepareAuraScript(spell_strikethrough_driver);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_STRIKETHROUGH_HIDDEN,
            SPELL_STRIKETHROUGH_RANK_1, SPELL_STRIKETHROUGH_RANK_2, SPELL_STRIKETHROUGH_RANK_3 });
    }

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* owner = GetTarget();
        if (!owner || owner->HasAura(SPELL_STRIKETHROUGH_HIDDEN))
            return;
        owner->CastSpell(owner, SPELL_STRIKETHROUGH_HIDDEN, true);
    }

    void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* owner = GetTarget();
        if (!owner)
            return;
        if (owner->HasAura(SPELL_STRIKETHROUGH_RANK_1) ||
            owner->HasAura(SPELL_STRIKETHROUGH_RANK_2) ||
            owner->HasAura(SPELL_STRIKETHROUGH_RANK_3))
            return;
        owner->RemoveAurasDueToSpell(SPELL_STRIKETHROUGH_HIDDEN);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_strikethrough_driver::HandleApply, EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_strikethrough_driver::HandleRemove, EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

// 320249 - hidden. EFFECT_0 BP=0; fill crit-damage Dummy. EFFECT_1 heal stays 0
// (driver already has a live crit-heal aura; filling it here would double).
class spell_strikethrough_hidden : public AuraScript
{
    PrepareAuraScript(spell_strikethrough_hidden);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_STRIKETHROUGH_RANK_1, SPELL_STRIKETHROUGH_RANK_2, SPELL_STRIKETHROUGH_RANK_3 });
    }

    void CalculateDamage(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        Unit* owner = GetUnitOwner();
        amount = owner ? StrikethroughCritDamagePct(owner) : 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_strikethrough_hidden::CalculateDamage, EFFECT_0, SPELL_AURA_MOD_CRIT_DAMAGE_BONUS);
    }
};

// 318220 - hidden proc. DBC already has RPPM 5 and white+yellow+heal+hostile+periodic+trap.
class spell_racing_pulse_proc : public AuraScript
{
    PrepareAuraScript(spell_racing_pulse_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_RACING_PULSE_BUFF,
            SPELL_RACING_PULSE_RANK_1, SPELL_RACING_PULSE_RANK_2, SPELL_RACING_PULSE_RANK_3 });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastRacingPulse(caster);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_racing_pulse_proc::HandleProc);
    }
};

// 318227 - haste rating, 4s, no stacks. DBC BP=0; fill from rank Dummy.
class spell_racing_pulse_buff : public AuraScript
{
    PrepareAuraScript(spell_racing_pulse_buff);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_RACING_PULSE_PROC,
            SPELL_RACING_PULSE_RANK_1, SPELL_RACING_PULSE_RANK_2, SPELL_RACING_PULSE_RANK_3 });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;

        Unit* owner = GetUnitOwner();
        if (!owner || !owner->HasAura(SPELL_RACING_PULSE_PROC))
        {
            amount = 0;
            return;
        }

        amount = RacingPulseRating(owner);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_racing_pulse_buff::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_RATING);
    }
};

// 318214 - hidden proc. DBC already has RPPM 3 and white+yellow+heal+hostile+periodic+trap.
class spell_honed_mind_proc : public AuraScript
{
    PrepareAuraScript(spell_honed_mind_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_HONED_MIND_BUFF,
            SPELL_HONED_MIND_RANK_1, SPELL_HONED_MIND_RANK_2, SPELL_HONED_MIND_RANK_3 });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastHonedMind(caster);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_honed_mind_proc::HandleProc);
    }
};

// 318216 - mastery rating, 10s, no stacks. DBC BP=0; fill from rank Dummy.
class spell_honed_mind_buff : public AuraScript
{
    PrepareAuraScript(spell_honed_mind_buff);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_HONED_MIND_PROC,
            SPELL_HONED_MIND_RANK_1, SPELL_HONED_MIND_RANK_2, SPELL_HONED_MIND_RANK_3 });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;

        Unit* owner = GetUnitOwner();
        if (!owner || !owner->HasAura(SPELL_HONED_MIND_PROC))
        {
            amount = 0;
            return;
        }

        amount = HonedMindRating(owner);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_honed_mind_buff::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_RATING);
    }
};

// 318218 - hidden proc. DBC mask is the same wide set as Racing Pulse; keep crits only.
class spell_deadly_momentum_proc : public AuraScript
{
    PrepareAuraScript(spell_deadly_momentum_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_DEADLY_MOMENTUM_BUFF,
            SPELL_DEADLY_MOMENTUM_RANK_1, SPELL_DEADLY_MOMENTUM_RANK_2, SPELL_DEADLY_MOMENTUM_RANK_3 });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return (eventInfo.GetHitMask() & PROC_HIT_CRITICAL) != 0;
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastDeadlyMomentum(caster);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_deadly_momentum_proc::CheckProc);
        OnProc += AuraProcFn(spell_deadly_momentum_proc::HandleProc);
    }
};

// 318219 - crit rating, 30s, max 5 stacks. Fill per-stack Dummy; engine multiplies.
class spell_deadly_momentum_buff : public AuraScript
{
    PrepareAuraScript(spell_deadly_momentum_buff);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_DEADLY_MOMENTUM_PROC,
            SPELL_DEADLY_MOMENTUM_RANK_1, SPELL_DEADLY_MOMENTUM_RANK_2, SPELL_DEADLY_MOMENTUM_RANK_3 });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;

        Unit* owner = GetUnitOwner();
        if (!owner || !owner->HasAura(SPELL_DEADLY_MOMENTUM_PROC))
        {
            amount = 0;
            return;
        }

        amount = DeadlyMomentumRatingPerStack(owner);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_deadly_momentum_buff::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_RATING);
    }
};

// 318212 - hidden proc. DBC already has RPPM 2 and TAKEN melee/spell/periodic/heal.
class spell_surging_vitality_proc : public AuraScript
{
    PrepareAuraScript(spell_surging_vitality_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_SURGING_VITALITY_BUFF,
            SPELL_SURGING_VITALITY_RANK_1, SPELL_SURGING_VITALITY_RANK_2, SPELL_SURGING_VITALITY_RANK_3 });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* caster = GetTarget())
            CastSurgingVitality(caster);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_surging_vitality_proc::HandleProc);
    }
};

// 318211 - vers rating, 20s, no stacks. DBC BP=0; fill from rank Scaled via CalcValue.
class spell_surging_vitality_buff : public AuraScript
{
    PrepareAuraScript(spell_surging_vitality_buff);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_SURGING_VITALITY_PROC,
            SPELL_SURGING_VITALITY_RANK_1, SPELL_SURGING_VITALITY_RANK_2, SPELL_SURGING_VITALITY_RANK_3 });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;

        Unit* owner = GetUnitOwner();
        if (!owner || !owner->HasAura(SPELL_SURGING_VITALITY_PROC))
        {
            amount = 0;
            return;
        }

        amount = SurgingVitalityRating(owner);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_surging_vitality_buff::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_RATING);
    }
};

// 318179 - hidden proc. DBC already has RPPM 4 haste and yellow+hostile flags.
class spell_gushing_wound_proc : public AuraScript
{
    PrepareAuraScript(spell_gushing_wound_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_GUSHING_WOUND_DOT, SPELL_GUSHING_WOUND_RANK });
    }

    void HandleProc(ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        if (!caster)
            return;
        if (Unit* target = ResolveGushingWoundTarget(caster, eventInfo))
            CastGushingWound(caster, target);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_gushing_wound_proc::HandleProc);
    }
};

// 318187 - target bleed. DBC BP=0; fill Dummy% of max(AP,SP). Do not divide by tick count.
class spell_gushing_wound_dot : public AuraScript
{
    PrepareAuraScript(spell_gushing_wound_dot);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_GUSHING_WOUND_PROC, SPELL_GUSHING_WOUND_RANK });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = false;

        Unit* owner = GetCaster();
        if (!owner || !owner->HasAura(SPELL_GUSHING_WOUND_PROC))
        {
            amount = 0;
            return;
        }

        amount = GushingWoundTickDamage(owner);
    }

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        if (aurEff->GetAmount() <= 0)
            return;

        if (Unit* owner = GetCaster())
            LabNotify(owner, "WOUND_TICK", Trinity::StringFormat("damage=%d", aurEff->GetAmount()));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_gushing_wound_dot::CalculateAmount, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_gushing_wound_dot::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

// 315573 - Glimpse buff. Dummy only; trim is PlayerScript OnSuccessfulSpellCast.
class spell_glimpse_of_clarity : public AuraScript
{
    PrepareAuraScript(spell_glimpse_of_clarity);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_GLIMPSE_PROC, SPELL_GLIMPSE_ITEM });
    }

    void Register() override { }
};

class player_glimpse_of_clarity : public PlayerScript
{
public:
    player_glimpse_of_clarity() : PlayerScript("player_glimpse_of_clarity") { }

    void OnSuccessfulSpellCast(Player* player, Spell* spell) override
    {
        TryGlimpseTrim(player, spell);
    }
};

// 316801 - 10s recharge buff. Aura 143/173 are NYI; Dummy comes from the driver.
class spell_ineffable_truth : public AuraScript
{
    PrepareAuraScript(spell_ineffable_truth);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_INEFFABLE_TRUTH_PROC,
            SPELL_INEFFABLE_TRUTH_RANK_1, SPELL_INEFFABLE_TRUTH_RANK_2 });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        amount = IneffableTruthPct(GetUnitOwner());
    }

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* owner = GetUnitOwner();
        int32 pct = IneffableTruthPct(owner);
        if (!_scaled)
        {
            if (Player* player = owner ? owner->ToPlayer() : nullptr)
            {
                ScaleExistingCooldowns(player, pct, true);
                _pct = pct;
                _scaled = true;
            }
        }

        int32 mult = pct > 0 ? (100 * 100 / (100 + pct)) : 100;
        LabNotify(owner, "RECHARGE", Trinity::StringFormat("pct=%d mult=%d", pct, mult));
    }

    void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        if (!_scaled)
            return;

        Unit* owner = GetUnitOwner();
        if (Player* player = owner ? owner->ToPlayer() : nullptr)
            ScaleExistingCooldowns(player, _pct, false);
        _scaled = false;
        _pct = 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ineffable_truth::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_RECOVERY_RATE);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ineffable_truth::CalculateAmount, EFFECT_1, SPELL_AURA_MOD_RECOVERY_RATE_2);
        AfterEffectApply += AuraEffectApplyFn(spell_ineffable_truth::HandleApply, EFFECT_0, SPELL_AURA_MOD_RECOVERY_RATE, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ineffable_truth::HandleRemove, EFFECT_0, SPELL_AURA_MOD_RECOVERY_RATE, AURA_EFFECT_HANDLE_REAL);
    }

private:
    bool _scaled = false;
    int32 _pct = 0;
};

class player_ineffable_truth : public PlayerScript
{
public:
    player_ineffable_truth() : PlayerScript("player_ineffable_truth") { }

    void OnCooldownStart(Player* player, SpellInfo const* spellInfo, uint32 itemId, int32& cooldown, uint32& /*categoryId*/, int32& categoryCooldown) override
    {
        if (!player || !spellInfo || !player->HasAura(SPELL_INEFFABLE_TRUTH_BUFF))
            return;
        if (itemId || spellInfo->IsPassive())
            return;
        if (IsIneffableTruthOwnSpell(spellInfo->Id) || IsGlimpseExcludedSpell(spellInfo->Id))
            return;

        int32 pct = IneffableTruthPct(player);
        ApplyIneffableTruthRate(cooldown, pct);
        ApplyIneffableTruthRate(categoryCooldown, pct);
    }

    void OnChargeRecoveryTimeStart(Player* player, uint32 chargeCategoryId, int32& chargeRecoveryTime) override
    {
        if (!player || !player->HasAura(SPELL_INEFFABLE_TRUTH_BUFF))
            return;
        if (!IneffableTruthScalesChargeCategory(player, chargeCategoryId))
            return;

        ApplyIneffableTruthRate(chargeRecoveryTime, IneffableTruthPct(player));
    }
};

// 315175 - CorruptionEffects Grasping Tendrils. Taken proc; do not compare thresholds.
class spell_grasping_tendrils_proc : public AuraScript
{
    PrepareAuraScript(spell_grasping_tendrils_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_GRASPING_TENDRILS_SLOW });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* owner = GetTarget())
            CastGraspingTendrils(owner);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_grasping_tendrils_proc::HandleProc);
    }
};

// 315176 - 5s snare. Amount = min(effectiveCorruption+10, 99).
class spell_grasping_tendrils_slow : public AuraScript
{
    PrepareAuraScript(spell_grasping_tendrils_slow);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_GRASPING_TENDRILS_PROC });
    }

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        Player* player = GetUnitOwner() ? GetUnitOwner()->ToPlayer() : nullptr;
        if (!player)
        {
            amount = 0;
            return;
        }
        amount = GraspingTendrilsSlowPct(player);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_grasping_tendrils_slow::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_DECREASE_SPEED);
    }
};

// 315169 - CorruptionEffects Eye of Corruption. Class abilities; do not compare thresholds.
class spell_eye_of_corruption : public AuraScript
{
    PrepareAuraScript(spell_eye_of_corruption);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_EYE_OF_CORRUPTION });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* owner = GetTarget())
            CastEyeOfCorruption(owner);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_eye_of_corruption::HandleProc);
    }
};

// 315184 - CorruptionEffects Grand Delusions. Taken proc. Do not use cloak 313301.
class spell_grand_delusions : public AuraScript
{
    PrepareAuraScript(spell_grand_delusions);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_GRAND_DELUSIONS });
    }

    void HandleProc(ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        if (Unit* owner = GetTarget())
            CastGrandDelusions(owner);
    }

    void Register() override
    {
        OnProc += AuraProcFn(spell_grand_delusions::HandleProc);
    }
};

void AddSC_corruption_spell_scripts()
{
    RegisterSpellScript(spell_corruption_infinite_stars);
    RegisterAuraScript(spell_corruption_rank_driver);
    RegisterAuraScript(spell_infinite_stars_proc);
    RegisterSpellScript(spell_infinite_stars_selector);
    RegisterSpellScript(spell_infinite_stars_damage);
    RegisterAuraScript(spell_twilight_devastation_proc);
    RegisterSpellScript(spell_twilight_devastation_beam);
    RegisterSpellScript(spell_twilight_devastation_damage);
    RegisterAreaTriggerAI(at_twilight_devastation);
    RegisterAuraScript(spell_echoing_void_proc);
    RegisterAuraScript(spell_echoing_void_collapse);
    RegisterSpellScript(spell_echoing_void_damage);
    RegisterAuraScript(spell_twisted_appendage_proc);
    RegisterAuraScript(spell_twisted_appendage_flay);
    RegisterCreatureAI(npc_twisted_appendage);
    RegisterAuraScript(spell_void_ritual_proc);
    RegisterAuraScript(spell_void_ritual_end_is_coming);
    RegisterAuraScript(spell_strikethrough_driver);
    RegisterAuraScript(spell_strikethrough_hidden);
    RegisterAuraScript(spell_racing_pulse_proc);
    RegisterAuraScript(spell_racing_pulse_buff);
    RegisterAuraScript(spell_honed_mind_proc);
    RegisterAuraScript(spell_honed_mind_buff);
    RegisterAuraScript(spell_deadly_momentum_proc);
    RegisterAuraScript(spell_deadly_momentum_buff);
    RegisterAuraScript(spell_surging_vitality_proc);
    RegisterAuraScript(spell_surging_vitality_buff);
    RegisterAuraScript(spell_gushing_wound_proc);
    RegisterAuraScript(spell_gushing_wound_dot);
    RegisterAuraScript(spell_glimpse_of_clarity);
    RegisterPlayerScript(player_glimpse_of_clarity);
    RegisterAuraScript(spell_ineffable_truth);
    RegisterPlayerScript(player_ineffable_truth);
    RegisterAuraScript(spell_grasping_tendrils_proc);
    RegisterAuraScript(spell_grasping_tendrils_slow);
    RegisterAuraScript(spell_eye_of_corruption);
    RegisterAuraScript(spell_grand_delusions);
}
