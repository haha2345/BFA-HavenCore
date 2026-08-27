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
 */

#include "AreaTrigger.h"
#include "AreaTriggerAI.h"
#include "Chat.h"
#include "Log.h"
#include "StringFormat.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
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
    int32 pct = INFINITE_STARS_RANK1_PCT_FALLBACK;
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(InfiniteStarsRankSpell(caster)))
    {
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_1))
            pct = effect->BasePoints;
        else
        {
            static bool logged = false;
            if (!logged)
            {
                logged = true;
                TC_LOG_ERROR("scripts", "InfiniteStars: rank EFFECT_1 missing, using %d%%", INFINITE_STARS_RANK1_PCT_FALLBACK);
            }
        }
    }

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
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(TwilightRankSpell(caster)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_0))
            if (effect->BasePoints > 0)
                // DBC stores 60/120/180; tooltip is $s1/10 percent of health.
                return float(effect->BasePoints) / 10.0f / 100.0f;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "TwilightDevastation: rank EFFECT_0 missing, using bp %d",
            TWILIGHT_RANK1_BP_FALLBACK);
    }
    return float(TWILIGHT_RANK1_BP_FALLBACK) / 10.0f / 100.0f;
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
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(EchoingVoidRankSpell(caster)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_0))
            if (effect->BasePoints > 0)
                // DBC stores 40/60/100; tooltip is $s1/100 percent of health (rank 1 = 0.4%).
                return float(effect->BasePoints) / 100.0f / 100.0f;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "EchoingVoid: rank EFFECT_0 missing, using bp %d",
            ECHOING_VOID_RANK1_BP_FALLBACK);
    }
    return float(ECHOING_VOID_RANK1_BP_FALLBACK) / 100.0f / 100.0f;
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
    int32 pct = TWISTED_APPENDAGE_RANK1_PCT_FALLBACK;
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(TwistedAppendageRankSpell(owner)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_1))
            pct = effect->BasePoints;

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
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(VoidRitualRankSpell(owner)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_0))
            if (effect->BasePoints >= 1)
                return effect->BasePoints;

    static bool logged = false;
    if (!logged)
    {
        logged = true;
        TC_LOG_ERROR("scripts", "VoidRitual: rank EFFECT_0 missing, using rating %d",
            VOID_RITUAL_RANK1_RATING_FALLBACK);
    }
    return VOID_RITUAL_RANK1_RATING_FALLBACK;
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
}

// 324889/324890/324891 - 腐蚀 - 无尽之星 (DBC has no aura effect; AfterCast applies the hidden proc)
class spell_corruption_infinite_stars : public SpellScript
{
    PrepareSpellScript(spell_corruption_infinite_stars);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_INFINITE_STARS_HIDDEN_PROC });
    }

    void HandleAfterCast()
    {
        if (Unit* caster = GetCaster())
            caster->CastSpell(caster, SPELL_INFINITE_STARS_HIDDEN_PROC, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_corruption_infinite_stars::HandleAfterCast);
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

void AddSC_corruption_spell_scripts()
{
    RegisterSpellScript(spell_corruption_infinite_stars);
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
}
