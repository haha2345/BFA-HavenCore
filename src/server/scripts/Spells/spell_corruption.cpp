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
    int32 bp = TWILIGHT_RANK1_BP_FALLBACK;
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(TwilightRankSpell(caster)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_0))
            bp = effect->BasePoints;
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
    int32 bp = ECHOING_VOID_RANK1_BP_FALLBACK;
    if (SpellInfo const* rank = sSpellMgr->GetSpellInfo(EchoingVoidRankSpell(caster)))
        if (SpellEffectInfo const* effect = rank->GetEffect(EFFECT_0))
            bp = effect->BasePoints;
    // DBC stores 40/60/100; tooltip is $s1/100 percent of health (rank 1 = 0.4%).
    return float(bp) / 100.0f / 100.0f;
}

uint32 EchoingVoidPeriodMs()
{
    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_ECHOING_VOID_COLLAPSE))
        if (SpellEffectInfo const* effect = info->GetEffect(EFFECT_0))
            if (effect->ApplyAuraPeriod)
                return effect->ApplyAuraPeriod;
    return ECHOING_VOID_PERIOD_FALLBACK_MS;
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
// (AfterCast, not OnHit — this is an AoE). Shared with Hivemind: no 317014 → do nothing.
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

        if (!caster->HasAura(SPELL_ECHOING_VOID_PROC) || !caster->HasAura(SPELL_ECHOING_VOID_COLLAPSE))
            return;

        int32 damage = int32(float(caster->GetMaxHealth()) * EchoingVoidHealthPct(caster));
        if (damage < 1)
            damage = 1;

        SetHitDamage(damage);
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(SPELL_ECHOING_VOID_PROC))
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
}
