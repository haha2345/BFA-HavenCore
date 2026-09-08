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

#include "CellImpl.h"
#include "GridNotifiers.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellMgr.h"
#include "SpellAuraEffects.h"

enum MasterySpells
{
    SPELL_MAGE_MASTERY_ICICLES               = 76613,
    SPELL_MAGE_ICICLE_DAMAGE                 = 148022,
    SPELL_MAGE_ICICLE_AURA                   = 205473,
    SPELL_MAGE_ICICLE_PERIODIC_TRIGGER       = 148023,
    SPELL_MAGE_FROSTBOLT                     = 116,
    SPELL_MAGE_FROSTBOLT_TRIGGER             = 228597,
    SPELL_MAGE_ICE_NINE                      = 214664,
    SPELL_MAGE_BLACK_ICE                     = 195615,
    SPELL_MAGE_GLACIAL_SPIKE                 = 199786,
    SPELL_MAGE_GLACIAL_SPIKE_PROC            = 199844,
    SPELL_MAGE_GLACIAL_SPIKE_DAMAGE          = 228600,
    SPELL_MAGE_GLACIAL_SPIKE_AMOUNT          = 214325,
    SPELL_MAGE_IGNITE                        = 12846,
    SPELL_MAGE_IGNITE_AURA                   = 12654,
    SPELL_MAGE_SPLITTING_ICE                 = 56377,
    SPELL_MAGE_SCORCH                        = 2948
};

const int IcicleAuras[5] = { 214124, 214125, 214126, 214127, 214130 };
const int IcicleHits[5] = { 148017, 148018, 148019, 148020, 148021 };

// Mastery: Icicles - 76613
class spell_mastery_icicles_proc : public AuraScript
{
    PrepareAuraScript(spell_mastery_icicles_proc);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        bool _spellCanProc = (eventInfo.GetSpellInfo()->Id == SPELL_MAGE_FROSTBOLT || eventInfo.GetSpellInfo()->Id == SPELL_MAGE_FROSTBOLT_TRIGGER);

        if (_spellCanProc)
            return true;
        return false;
    }

    void OnProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetDamageInfo()->GetVictim();
        Unit* caster = eventInfo.GetDamageInfo()->GetAttacker();
        if (!target || !caster)
            return;

        Player* player = caster->ToPlayer();

        if (!player)
            return;

        // Calculate damage
        int32 hitDamage = eventInfo.GetDamageInfo()->GetDamage() + eventInfo.GetDamageInfo()->GetAbsorb();

        // if hitDamage == 0 we have a miss, so we need to except this variant
        if (hitDamage != 0)
        {
            bool icilesAddSecond = false;

            if (caster->HasAura(SPELL_MAGE_ICE_NINE))
            {
                if (roll_chance_i(20))
                    icilesAddSecond = true;
            }

            float masteryCoef = 0.0f;
            if (SpellEffectInfo const* aura107 = GetSpellInfo()->GetEffect(EFFECT_2))
                masteryCoef = aura107->BonusCoefficient;
            hitDamage = int32(hitDamage * player->m_activePlayerData->Mastery * masteryCoef);

            int32 maxIcicles = 0;
            if (SpellEffectInfo const* dummy5 = GetSpellInfo()->GetEffect(EFFECT_1))
                maxIcicles = dummy5->CalcValue();
            int32 visualSlots = int32(sizeof(IcicleAuras) / sizeof(IcicleAuras[0]));
            if (maxIcicles > visualSlots)
                maxIcicles = visualSlots;
            if (maxIcicles <= 0)
                return;

            // Prevent huge hits on player after hitting low level creatures
            if (player->getLevel() > target->getLevel())
                hitDamage = std::min(int32(hitDamage), int32(target->GetMaxHealth()));

            // We need to get the first free icicle slot
            int8 icicleFreeSlot = -1; // -1 means no free slot
            int8 icicleSecondFreeSlot = -1; // -1 means no free slot
            for (int8 l_I = 0; l_I < maxIcicles; ++l_I)
            {
                if (!player->HasAura(IcicleAuras[l_I]))
                {
                    icicleFreeSlot = l_I;
                    if (icilesAddSecond && (l_I + 1) < maxIcicles)
                        icicleSecondFreeSlot = l_I + 1;
                    break;
                }
            }

            switch (icicleFreeSlot)
            {
                case -1:
                {
                    // We need to find the icicle with the smallest duration.
                    int8 smallestIcicle = 0;
                    int32 minDuration = 0xFFFFFF;
                    for (int8 i = 0; i < maxIcicles; i++)
                    {
                        if (Aura* tmpCurrentAura = player->GetAura(IcicleAuras[i]))
                        {
                            if (minDuration > tmpCurrentAura->GetDuration())
                            {
                                minDuration = tmpCurrentAura->GetDuration();
                                smallestIcicle = i;
                            }
                        }
                    }

                    // Launch the icicle with the smallest duration
                    if (AuraEffect* currentIcicleAuraEffect = player->GetAuraEffect(IcicleAuras[smallestIcicle], EFFECT_0))
                    {
                        int32 basePoints = currentIcicleAuraEffect->GetAmount();

                        if (caster->HasAura(SPELL_MAGE_BLACK_ICE))
                        {
                            if (roll_chance_i(20))
                                basePoints *= 2;
                        }

                        player->CastSpell(target, IcicleHits[smallestIcicle], true);
                        player->CastCustomSpell(target, SPELL_MAGE_ICICLE_DAMAGE, &basePoints, NULL, NULL, true);
                        player->RemoveAura(IcicleAuras[smallestIcicle]);
                    }

                    icicleFreeSlot = smallestIcicle;
                    // No break because we'll add the icicle in the next case
                }
                /* fallthrough */
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                {

                    if (Aura* currentIcicleAura = player->AddAura(IcicleAuras[icicleFreeSlot], player))
                    {
                        if (AuraEffect* effect = currentIcicleAura->GetEffect(EFFECT_0))
                            effect->SetAmount(hitDamage);

                        player->AddAura(SPELL_MAGE_ICICLE_AURA, player);

                        if (caster->HasSpell(SPELL_MAGE_GLACIAL_SPIKE))
                        {
                            if (Aura* glacialSpikeProc = player->GetAura(SPELL_MAGE_ICICLE_AURA))
                            {
                                if (glacialSpikeProc->GetStackAmount() == maxIcicles)
                                    player->CastSpell(player, SPELL_MAGE_GLACIAL_SPIKE_PROC, true);
                            }
                        }
                    }
                    break;
                }
            }

            switch (icicleSecondFreeSlot)
            {
                case -1:
                {
                    if (icilesAddSecond)
                    {
                        // We need to find the icicle with the smallest duration.
                        int8 smallestIcicle = 0;
                        int32 minDuration = 0xFFFFFF;
                        for (int8 i = 0; i < maxIcicles; i++)
                        {
                            if (Aura* tmpCurrentAura = player->GetAura(IcicleAuras[i]))
                            {
                                if (minDuration > tmpCurrentAura->GetDuration())
                                {
                                    minDuration = tmpCurrentAura->GetDuration();
                                    smallestIcicle = i;
                                }
                            }
                        }

                        // Launch the icicle with the smallest duration
                        if (AuraEffect* currentIcicleAuraEffect = player->GetAuraEffect(IcicleAuras[smallestIcicle], EFFECT_0))
                        {
                            int32 basePoints = currentIcicleAuraEffect->GetAmount();

                            if (caster->HasAura(SPELL_MAGE_BLACK_ICE))
                            {
                                if (roll_chance_i(20))
                                    basePoints *= 2;
                            }

                            player->CastSpell(target, IcicleHits[smallestIcicle], true);
                            player->CastCustomSpell(target, SPELL_MAGE_ICICLE_DAMAGE, &basePoints, NULL, NULL, true);
                            player->RemoveAura(IcicleAuras[smallestIcicle]);
                        }

                        icicleSecondFreeSlot = smallestIcicle;
                        // No break because we'll add the icicle in the next case
                    }
                }
                /* fallthrough */
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                {
                    if (Aura* currentIcicleAura = player->AddAura(IcicleAuras[icicleSecondFreeSlot], player))
                    {
                        if (AuraEffect* effect = currentIcicleAura->GetEffect(EFFECT_0))
                            effect->SetAmount(hitDamage);

                        player->AddAura(SPELL_MAGE_ICICLE_AURA, player);

                        if (caster->HasSpell(SPELL_MAGE_GLACIAL_SPIKE))
                        {
                            if (Aura* glacialSpikeProc = player->GetAura(SPELL_MAGE_ICICLE_AURA))
                            {
                                if (glacialSpikeProc->GetStackAmount() == maxIcicles)
                                    player->CastSpell(player, SPELL_MAGE_GLACIAL_SPIKE_PROC, true);
                            }
                        }
                    }
                    break;
                }
            }
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_mastery_icicles_proc::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_mastery_icicles_proc::OnProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// Icicles (Aura Remove) - (214124, 214125, 214126, 214127, 214130)
class spell_mastery_icicles_mod_aura : public AuraScript
{
    PrepareAuraScript(spell_mastery_icicles_mod_aura);

    void OnRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        if (Aura* aur = caster->GetAura(SPELL_MAGE_ICICLE_AURA))
            aur->ModStackAmount(-1);

        if (caster->HasAura(SPELL_MAGE_GLACIAL_SPIKE_PROC))
             caster->RemoveAura(SPELL_MAGE_GLACIAL_SPIKE_PROC);
    }

    void Register() override
    {
        OnEffectRemove += AuraEffectRemoveFn(spell_mastery_icicles_mod_aura::OnRemove, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

// Icicles (periodic) - 148023
class spell_mastery_icicles_periodic : public AuraScript
{
    PrepareAuraScript(spell_mastery_icicles_periodic);

    uint32 icicles[5];
    int32 icicleCount;

    void OnApply(AuraEffect const* /*l_AurEff*/, AuraEffectHandleModes /*l_Mode*/)
    {
        icicleCount = 0;
        if (Unit* caster = GetCaster())
        {
            for (uint32 l_I = 0; l_I < 5; ++l_I)
            {
                if (caster->HasAura(IcicleAuras[l_I]))
                    icicles[icicleCount++] = IcicleAuras[l_I];
            }
        }
    }

    void OnTick(AuraEffect const* /*aurEff*/)
    {
        if (Unit* caster = GetCaster())
        {
            if (AuraEffect* aura = caster->GetAuraEffect(GetSpellInfo()->Id, EFFECT_0))
            {
                // Maybe not the good target selection ...
                if (Unit* target = ObjectAccessor::GetUnit(*caster, caster->Variables.GetValue<ObjectGuid>("IciclesTarget")))
                {
                    if (target->IsAlive())
                    {
                        int32 amount = aura->GetAmount();
                        if (Aura* currentIcicleAura = caster->GetAura(icicles[amount]))
                        {
                            int32 basePoints = currentIcicleAura->GetEffect(0)->GetAmount();

                            if (caster->HasAura(SPELL_MAGE_BLACK_ICE))
                            {
                                if (roll_chance_i(20))
                                    basePoints *= 2;
                            }

                            caster->CastSpell(target, IcicleHits[amount], true);
                            caster->CastCustomSpell(target, SPELL_MAGE_ICICLE_DAMAGE, &basePoints, NULL, NULL, true);
                            caster->RemoveAura(IcicleAuras[amount]);
                        }

                        if (++amount >= icicleCount)
                            caster->RemoveAura(aura->GetBase());
                        else
                            aura->SetAmount(amount);
                    }
                    else
                        caster->RemoveAura(aura->GetBase());
                }
            }
        }
    }

    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(spell_mastery_icicles_periodic::OnApply, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_mastery_icicles_periodic::OnTick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// Glacial Spike - 199786
class spell_mastery_icicles_glacial_spike : public SpellScript
{
    PrepareSpellScript(spell_mastery_icicles_glacial_spike);

    int32 IcicleDamage;

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MAGE_SPLITTING_ICE,
                SPELL_MAGE_GLACIAL_SPIKE_DAMAGE,
                SPELL_MAGE_ICICLE_AURA,
                SPELL_MAGE_GLACIAL_SPIKE_PROC
            });
    }

    void HandleOnCast()
    {
        Player* player = GetCaster()->ToPlayer();

        if (!player)
            return;

        // Remove aura with visual icicle and get damage per stored icicle
        for (int8 l_I = 0; l_I < 5; ++l_I)
        {
            if (Aura* currentIcicleAura = player->GetAura(IcicleAuras[l_I]))
            {
                int32 basePoints = currentIcicleAura->GetEffect(0)->GetAmount();
                player->RemoveAura(IcicleAuras[l_I]);

                IcicleDamage += basePoints;
            }
        }
    }

    void HandleOnHit(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        Unit* explTarget = GetExplTargetUnit();
        if (!caster || !target || !explTarget)
            return;

        int32 damage = GetHitDamage();
        damage += IcicleDamage;

        if (GetCaster()->HasAura(SPELL_MAGE_SPLITTING_ICE))
            if (SpellEffectInfo const* eff1 = sSpellMgr->GetSpellInfo(SPELL_MAGE_SPLITTING_ICE)->GetEffect(EFFECT_1))
                if (target != explTarget)
                    damage = CalculatePct(damage, eff1->CalcValue());

        caster->CastCustomSpell(target, SPELL_MAGE_GLACIAL_SPIKE_DAMAGE, &damage, NULL, NULL, true);

        if (caster->HasAura(SPELL_MAGE_ICICLE_AURA))
            caster->RemoveAurasDueToSpell(SPELL_MAGE_ICICLE_AURA);

        if (caster->HasAura(SPELL_MAGE_GLACIAL_SPIKE_PROC))
            caster->RemoveAurasDueToSpell(SPELL_MAGE_GLACIAL_SPIKE_PROC);
    }

    void Register() override
    {
        OnCast += SpellCastFn(spell_mastery_icicles_glacial_spike::HandleOnCast);
        OnEffectHitTarget += SpellEffectFn(spell_mastery_icicles_glacial_spike::HandleOnHit, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// 148022 - Icicle Damage
class spell_mage_icicle_damage : public SpellScript
{
    PrepareSpellScript(spell_mage_icicle_damage);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MAGE_SPLITTING_ICE
            });
    }

    void HandleOnHit()
    {
        Unit* explTarget = GetExplTargetUnit();
        Unit* hitUnit = GetHitUnit();
        if (!hitUnit || !explTarget)
            return;

        if (GetCaster()->HasAura(SPELL_MAGE_SPLITTING_ICE))
            if (SpellEffectInfo const* eff1 = sSpellMgr->GetSpellInfo(SPELL_MAGE_SPLITTING_ICE)->GetEffect(EFFECT_1))
                if (hitUnit != explTarget)
                    SetHitDamage(CalculatePct(GetHitDamage(), eff1->CalcValue()));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_mage_icicle_damage::HandleOnHit);
    }
};

enum
{
    SPELL_MAGE_SEARING_TOUCH = 269644,
};

// 12846 - Mastery : Ignite
// Called by Fireball - 133, Inferno Blast - 108853, Scorch - 2948, Pyroblast - 11366, Meteor - 153564, Flamestrike - 2120
class spell_mastery_ignite : public SpellScriptLoader
{
public:
    spell_mastery_ignite() : SpellScriptLoader("spell_mastery_ignite") { }

    class spell_mastery_ignite_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_mastery_ignite_SpellScript);

        void HandleCritChance(Unit* victim, float& chance)
        {
            if (GetSpellInfo()->Id != SPELL_MAGE_SCORCH)
                return;

            Unit* caster = GetCaster();
            if (!caster || !victim || !caster->HasAura(SPELL_MAGE_SEARING_TOUCH))
                return;

            if (AuraEffect const* dummy30 = caster->GetAuraEffect(SPELL_MAGE_SEARING_TOUCH, EFFECT_0))
                if (victim->HealthBelowPct(dummy30->GetAmount()))
                    chance = 100.f;
        }

        void HandleOnHit()
        {
            if (GetSpellInfo()->Id != SPELL_MAGE_SCORCH)
                return;

            Unit* caster = GetCaster();
            Unit* target = GetHitUnit();
            if (!caster || !target || !caster->HasAura(SPELL_MAGE_SEARING_TOUCH))
                return;

            AuraEffect const* dummy30 = caster->GetAuraEffect(SPELL_MAGE_SEARING_TOUCH, EFFECT_0);
            AuraEffect const* dummy150 = caster->GetAuraEffect(SPELL_MAGE_SEARING_TOUCH, EFFECT_1);
            if (!dummy30 || !dummy150)
                return;

            if (!target->HealthBelowPct(dummy30->GetAmount()))
                return;

            int32 damage = GetHitDamage();
            AddPct(damage, dummy150->GetAmount());
            SetHitDamage(damage);
        }

        void HandleAfterHit()
        {
            if (Unit* caster = GetCaster())
            {
                if (Unit* target = GetHitUnit())
                {
                    if (caster->GetTypeId() == TYPEID_PLAYER && caster->HasAura(SPELL_MAGE_IGNITE) && caster->getLevel() >= 78)
                    {
                        const SpellInfo* igniteAura = sSpellMgr->GetSpellInfo(SPELL_MAGE_IGNITE_AURA);
                        if (GetSpellInfo()->Id != SPELL_MAGE_IGNITE_AURA && igniteAura != nullptr)
                        {
                            float dummy75 = 0.0f;
                            if (SpellInfo const* igniteMastery = sSpellMgr->GetSpellInfo(SPELL_MAGE_IGNITE))
                                if (SpellEffectInfo const* eff1 = igniteMastery->GetEffect(EFFECT_1))
                                    dummy75 = float(eff1->CalcValue());
                            float masteryValue = caster->ToPlayer()->m_activePlayerData->Mastery * dummy75 / 100.0f;

                            int32 basePoints = GetHitDamage() /*+ GetAbsorbedDamage()*/;
                            if (basePoints)
                            {
                                // Hot Streak ignite tick x2 observation window, not Dummy
                                if (caster->Variables.GetValue<int32>("MageHotStreakIgnite", 0))
                                    basePoints *= 2;

                                basePoints = int32(CalculatePct(basePoints, masteryValue));

                                if (igniteAura->GetEffect(EFFECT_0)->Amplitude > 0)
                                    basePoints = basePoints / (igniteAura->GetMaxDuration() / igniteAura->GetEffect(EFFECT_0)->Amplitude);

                                if (Aura* previousIgnite = target->GetAura(SPELL_MAGE_IGNITE_AURA, caster->GetGUID()))
                                {
                                    if (AuraEffect* igniteEffect = previousIgnite->GetEffect(EFFECT_0))
                                    {
                                        if (uint32 amplitude = igniteEffect->GetPeriod())
                                            basePoints += (igniteEffect->GetAmount() * (previousIgnite->GetDuration() / amplitude)) / (previousIgnite->GetMaxDuration() / amplitude);
                                    }
                                }

                                if (target->IsHostileTo(caster))
                                    caster->CastCustomSpell(target, SPELL_MAGE_IGNITE_AURA, &basePoints, NULL, NULL, true);
                            }
                        }
                    }
                }
            }
        }

        void Register() override
        {
            OnCalcCritChance += SpellOnCalcCritChanceFn(spell_mastery_ignite_SpellScript::HandleCritChance);
            OnHit += SpellHitFn(spell_mastery_ignite_SpellScript::HandleOnHit);
            AfterHit += SpellHitFn(spell_mastery_ignite_SpellScript::HandleAfterHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_mastery_ignite_SpellScript();
    }
};

// Mastery: Ignite - 12846
class IgniteOrderPred
{
public:
    IgniteOrderPred(Unit const* base, bool ascending = true) : _ascending(ascending), _base(base) { }

    bool operator()(Unit const* objA, Unit const* objB) const
    {
        float valA = 0;
        float valB = 0;
        if (AuraEffect* eff = objA->GetAuraEffect(SPELL_MAGE_IGNITE_AURA, EFFECT_0, _base->GetGUID()))
            valA = eff->GetDamage();
        if (AuraEffect* eff = objB->GetAuraEffect(SPELL_MAGE_IGNITE_AURA, EFFECT_0, _base->GetGUID()))
            valB = eff->GetDamage();
        return _ascending ? valA < valB : valA > valB;
    }

private:
    bool const _ascending;
    Unit const* _base;
};

class spell_mage_mastery_ignite : public AuraScript
{
    PrepareAuraScript(spell_mage_mastery_ignite);

    void HandleEffectPeriodic(AuraEffect const* /*aurEff*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        float dist = 8.0f; // observation window, not Dummy
        std::list<Unit*> targetList;
        std::list<Unit*> targetsWithIgnite;
        std::list<Unit*> targetsWithouthIgnite;

        Trinity::AnyUnitInObjectRangeCheck check(caster, caster->GetVisibilityRange());
        Trinity::UnitListSearcher<Trinity::AnyUnitInObjectRangeCheck> searcher(caster, targetList, check);
        Cell::VisitGridObjects(GetCaster(), searcher, caster->GetVisibilityRange());

        for (Unit* unit : targetList)
        {
            if (unit->IsTotem() || caster->IsFriendlyTo(unit))
                continue;

            if (unit->HasAura(SPELL_MAGE_IGNITE_AURA, caster->GetGUID()))
            {
                targetsWithIgnite.emplace_back(unit);
            }
            else
            {
                targetsWithouthIgnite.emplace_back(unit);
            }
        }
        for (Unit* igniter : targetsWithIgnite)
        {
            if (Aura* srcIgnite = igniter->GetAura(SPELL_MAGE_IGNITE_AURA, caster->GetGUID()))
            {
                std::list<Unit*> targetsToIgnite;
                std::list<Unit*> targetsToReIgnite;
                for (Unit* target : targetsWithouthIgnite)
                {
                    if (igniter->GetDistance(target) <= dist)
                    {
                        if (target->HasAura(SPELL_MAGE_IGNITE_AURA, caster->GetGUID()))
                            targetsToReIgnite.emplace_back(target);
                        else
                            targetsToIgnite.emplace_back(target);
                    }
                }
                Unit* target = nullptr;
                if (!targetsToIgnite.empty())
                {
                    Trinity::Containers::RandomResize(targetsToIgnite, 1);
                    target = targetsToIgnite.front();
                }
                else if (!targetsToReIgnite.empty())
                {
                    targetsToReIgnite.sort(IgniteOrderPred(caster));
                    target = targetsToReIgnite.front();
                }
                if (target)
                {
                    if (target->IsFriendlyTo(caster) || !target->IsVisible() || target->IsFriendlyTo(caster) || target->HasUnitFlag(UNIT_FLAG_IMMUNE_TO_PC) || target->HasUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC) || target->HasUnitFlag(UNIT_FLAG_NON_ATTACKABLE))
                        return;

                    // copy values of base dot
                    caster->AddAura(SPELL_MAGE_IGNITE_AURA, target);
                    if (Aura* ignite = target->GetAura(SPELL_MAGE_IGNITE_AURA, caster->GetGUID()))
                    {
                        ignite->SetMaxDuration(srcIgnite->GetMaxDuration());
                        ignite->SetDuration(srcIgnite->GetDuration());
                        for (AuraEffect* eff : ignite->GetAuraEffects())
                        {
                            if (!eff)
                                continue;
                            if (AuraEffect* baseEff = srcIgnite->GetEffect(eff->GetEffIndex()))
                            {
                                eff->SetPeriodicTimer(baseEff->GetPeriodicTimer());
                                eff->SetDamage(baseEff->GetDamage());
                                eff->ChangeAmount(baseEff->GetAmount());
                            }
                        }
                    }
                }
            }
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_mage_mastery_ignite::HandleEffectPeriodic, EFFECT_2, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// 77220 - Mastery - Chaotic Energy
class warlock_mastery_chaotic_energy : public PlayerScript
{
public:
    warlock_mastery_chaotic_energy() : PlayerScript("warlock_mastery_chaotic_energy") {}

    enum UsedSpells
    {
        SPELL_WARLOCK_CHAOTIC_ENERGIES_MASTERY  = 77220
    };

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/)
    {
        if (Aura* aura = attacker->GetAura(SPELL_WARLOCK_CHAOTIC_ENERGIES_MASTERY))
        {
            uint32 const maxDamageImprovePercent = uint32(ceil(float(aura->GetEffect(EFFECT_0)->GetAmount()) / 2.f));
            AddPct(damage, maxDamageImprovePercent + urand(0, maxDamageImprovePercent));
        }
    }
};

// 115636 - Mastery - Combo Strike
class monk_mastery_combo_strike : public PlayerScript
{
public:
    monk_mastery_combo_strike() : PlayerScript("monk_mastery_combo_strike") {}

    enum UsedSpells
    {
        SPELL_MONK_MASTERY_COMBO_STRIKE = 115636
    };

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* spellInfo)
    {
        if (!spellInfo)
            return;

        if (Aura* aura = attacker->GetAura(SPELL_MONK_MASTERY_COMBO_STRIKE))
        {
            uint32 lastUsedSpellId = attacker->Variables.GetValue<uint32>("monk_mastery_combo_strike", uint32(0));
            if (lastUsedSpellId != spellInfo->Id)
            {
                AddPct(damage, aura->GetEffect(EFFECT_0)->GetAmount());
                attacker->Variables.Set("monk_mastery_combo_strike", spellInfo->Id);
            }
        }
    }
};

void AddSC_mastery_spell_scripts()
{
    new spell_mastery_ignite();

    RegisterAuraScript(spell_mastery_icicles_proc);
    RegisterAuraScript(spell_mastery_icicles_periodic);
    RegisterAuraScript(spell_mastery_icicles_mod_aura);
    RegisterAuraScript(spell_mage_mastery_ignite);
    RegisterSpellScript(spell_mage_icicle_damage);
    RegisterSpellScript(spell_mastery_icicles_glacial_spike);

    new warlock_mastery_chaotic_energy();
    new monk_mastery_combo_strike();
}
