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

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellHistory.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include "Util.h"
#include <algorithm>

enum SeismicWaveSpells
{
    SPELL_AZERITE_OVERPOWER    = 7384,
    SPELL_SEISMIC_WAVE         = 277639,
    SPELL_SEISMIC_WAVE_PROC    = 278495,
    SPELL_SEISMIC_WAVE_DAMAGE  = 278497
};

enum ConcentratedFlameSpells
{
    SPELL_CONCENTRATED_FLAME         = 295373,
    SPELL_CONCENTRATED_FLAME_MISSILE = 295376,
    SPELL_CONCENTRATED_FLAME_DAMAGE  = 295374,
    SPELL_CONCENTRATED_FLAME_HEAL    = 295375
};

// 278495 Dummy 0 hidden proc. Aura 285 already applies this aura via HandleAuraLinked.
// Dummy 0 is the hook; 9.52 / 740 are not Dummy.
class spell_azerite_seismic_wave_proc : public AuraScript
{
    PrepareAuraScript(spell_azerite_seismic_wave_proc);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_SEISMIC_WAVE, SPELL_SEISMIC_WAVE_DAMAGE, SPELL_AZERITE_OVERPOWER });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* si = eventInfo.GetSpellInfo();
        return si && si->Id == SPELL_AZERITE_OVERPOWER;
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (!target)
            target = eventInfo.GetProcTarget();
        if (!caster || !target)
            return;

        caster->CastSpell(target, SPELL_SEISMIC_WAVE_DAMAGE, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_azerite_seismic_wave_proc::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_azerite_seismic_wave_proc::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// 278497 Dummy 0 damage hook. 10.0 yd is Rad1=13. Dummy 10 must not be rewritten as 9.52.
class spell_azerite_seismic_wave_damage : public SpellScript
{
    PrepareSpellScript(spell_azerite_seismic_wave_damage);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_SEISMIC_WAVE, SPELL_SEISMIC_WAVE_PROC });
    }

    void HandleDamage(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        int32 amount = 0;
        if (AuraEffect const* proc = caster->GetAuraEffect(SPELL_SEISMIC_WAVE_PROC, EFFECT_0))
            amount = proc->GetAmount();
        if (amount <= 0)
        {
            if (SpellInfo const* parent = sSpellMgr->GetSpellInfo(SPELL_SEISMIC_WAVE))
                if (SpellEffectInfo const* effect = parent->GetEffect(EFFECT_0))
                    amount = effect->CalcValue(caster);
        }

        SetHitDamage(std::max(amount, int32(0)));
    }

    void HandleDummy(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_azerite_seismic_wave_damage::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        OnEffectHitTarget += SpellEffectFn(spell_azerite_seismic_wave_damage::HandleDummy, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

// 295373 Dummy 100 is +100% per stack. 3 is not Dummy. 30s is Category 1852.
// 1500 is the GCD column. 16.71 is not Dummy. Do not Learn 299349.
class spell_azerite_concentrated_flame : public SpellScript
{
    PrepareSpellScript(spell_azerite_concentrated_flame);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_CONCENTRATED_FLAME_MISSILE, SPELL_CONCENTRATED_FLAME_DAMAGE, SPELL_CONCENTRATED_FLAME_HEAL });
    }

    void HandleOnCast()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        uint32 stacks = caster->Variables.GetValue<uint32>("az_concentrated_flame_bonus_stacks", 0);
        caster->Variables.Set("az_concentrated_flame_pending_stacks", stacks);
        stacks += 1;
        if (stacks >= 3)
        {
            stacks = 0;
            caster->GetSpellHistory()->ResetCooldown(SPELL_CONCENTRATED_FLAME, true);
            if (SpellInfo const* info = GetSpellInfo())
                caster->GetSpellHistory()->RestoreCharge(info->ChargeCategoryId);
        }
        caster->Variables.Set("az_concentrated_flame_bonus_stacks", stacks);
    }

    void Register() override
    {
        OnCast += SpellCastFn(spell_azerite_concentrated_flame::HandleOnCast);
    }
};

// 295376 Dummy 100 missile landing. Damage/heal from 295373 EFFECT_1 CalcValue + Dummy 100 * pending stacks.
class spell_azerite_concentrated_flame_missile : public SpellScript
{
    PrepareSpellScript(spell_azerite_concentrated_flame_missile);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_CONCENTRATED_FLAME, SPELL_CONCENTRATED_FLAME_DAMAGE, SPELL_CONCENTRATED_FLAME_HEAL });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        SpellInfo const* flame = sSpellMgr->GetSpellInfo(SPELL_CONCENTRATED_FLAME);
        if (!flame)
            return;

        SpellEffectInfo const* dmgEff = flame->GetEffect(EFFECT_1);
        SpellEffectInfo const* pctEff = flame->GetEffect(EFFECT_2);
        if (!dmgEff || !pctEff)
            return;

        int32 base = dmgEff->CalcValue(caster);
        int32 dummyPct = pctEff->BasePoints;
        uint32 stacks = caster->Variables.GetValue<uint32>("az_concentrated_flame_pending_stacks", 0);
        int32 amount = base + CalculatePct(base, dummyPct * int32(stacks));
        if (amount < 0)
            amount = 0;

        if (caster->IsFriendlyTo(target))
            caster->CastCustomSpell(target, SPELL_CONCENTRATED_FLAME_HEAL, &amount, nullptr, nullptr, true);
        else
            caster->CastCustomSpell(target, SPELL_CONCENTRATED_FLAME_DAMAGE, &amount, nullptr, nullptr, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_azerite_concentrated_flame_missile::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddSC_azerite_spell_scripts()
{
    RegisterAuraScript(spell_azerite_seismic_wave_proc);
    RegisterSpellScript(spell_azerite_seismic_wave_damage);
    RegisterSpellScript(spell_azerite_concentrated_flame);
    RegisterSpellScript(spell_azerite_concentrated_flame_missile);
}
