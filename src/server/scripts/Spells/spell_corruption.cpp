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
 */

#include "Chat.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellHistory.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

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

void NotifyStarVisual(Unit* caster, Unit* target, uint32 visual, float delay, bool missileOk)
{
    Player* player = caster->ToPlayer();
    if (!player || !player->IsGameMaster() || !player->GetSession())
        return;

    ChatHandler(player->GetSession()).PSendSysMessage(
        "[HavenLab] STAR_VISUAL spell=%u visual=%u delay=%.2f missile=%u target=%s",
        SPELL_INFINITE_STARS_MISSILE, visual, delay, missileOk ? 1u : 0u, target->GetName().c_str());
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
    NotifyStarVisual(caster, target, visual, delay, ok);

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

        caster->DealDamage(target, uint32(damage), nullptr, SPELL_DIRECT_DAMAGE, SPELL_SCHOOL_MASK_ARCANE, GetSpellInfo(), true);
        SetHitDamage(damage);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_infinite_stars_damage::HandleHit);
    }
};

void AddSC_corruption_spell_scripts()
{
    RegisterSpellScript(spell_corruption_infinite_stars);
    RegisterAuraScript(spell_infinite_stars_proc);
    RegisterSpellScript(spell_infinite_stars_selector);
    RegisterSpellScript(spell_infinite_stars_damage);
}
