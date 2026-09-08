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

#include "AreaTrigger.h"
#include "AreaTriggerAI.h"
#include "GameTime.h"
#include "Containers.h"
#include "GridNotifiers.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellHistory.h"
#include "SpellMgr.h"
#include "SpellPackets.h"
#include "SpellScript.h"
#include <algorithm>

enum MonkSpells
{
    ITEM_MONK_T14_TANK_4P                               = 123159,
    MONK_NPC_BLACK_OX_STATUE                            = 61146,
    MONK_NPC_JADE_SERPENT_STATUE                        = 60849,
    SPELL_MONK_BLACKOUT_KICK_DOT                        = 128531,
    SPELL_MONK_BLACKOUT_KICK_HEAL                       = 128591,
    SPELL_MONK_BLACKOUT_STRIKE                          = 205523,
    SPELL_MONK_BLACKOUT_KICK                            = 100784,
    SPELL_MONK_BLACKOUT_KICK_PROC                       = 116768,
    SPELL_MONK_BLACKOUT_KICK_TRIGGERED                  = 228649,
    SPELL_MONK_BLACK_OX_BREW                            = 115399,
    SPELL_MONK_BREATH_OF_FIRE                           = 115181,
    SPELL_MONK_BREATH_OF_FIRE_CONFUSED                  = 123393,
    SPELL_MONK_BREATH_OF_FIRE_DOT                       = 123725,
    SPELL_MONK_CHI_BURST_DAMAGE                         = 148135,
    SPELL_MONK_CHI_BURST_HEAL                           = 130654,
    SPELL_MONK_CHI_TORPEDO_DAMAGE                       = 117993,
    SPELL_MONK_CHI_TORPEDO_HEAL                         = 124040,
    SPELL_MONK_CHI_WAVE_DAMAGE                          = 132467,
    SPELL_MONK_CHI_WAVE_HEAL                            = 132463,
    SPELL_MONK_CHI_WAVE_HEALING_BOLT                    = 132464,
    SPELL_MONK_CHI_WAVE_TALENT_AURA                     = 115098,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_CHANNEL         = 117952,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_CHI_PROC        = 123333,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK       = 117962,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK_CD    = 117953,
    SPELL_MONK_CRACKLING_JADE_SHOCK_BUMP                = 117962,
    SPELL_MONK_CREATE_CHI_SPHERE                        = 121286,
    SPELL_MONK_DISABLE                                  = 116095,
    SPELL_MONK_DISABLE_ROOT                             = 116706,
    SPELL_MONK_DIZZYING_HAZE                            = 116330,
    SPELL_MONK_ELUSIVE_BRAWLER                          = 195630,
    SPELL_MONK_ELUSIVE_BREW                             = 115308,
    SPELL_MONK_ELUSIVE_BREW_STACKS                      = 128939,
    SPELL_MONK_EMINENCE_HEAL                            = 126890,
    SPELL_MONK_ENHANCED_ROLL                            = 157361,
    SPELL_MONK_ENVELOPING_MIST                          = 124682,
    SPELL_MONK_ENVELOPING_MIST_HEAL                     = 132120,
    SPELL_MONK_ESSENCE_FONT_HEAL                        = 191840,
    SPELL_MONK_FISTS_OF_FURY                            = 113656,
    SPELL_MONK_FISTS_OF_FURY_DAMAGE                     = 117418,
    SPELL_MONK_FLYING_SERPENT_KICK                      = 101545,
    SPELL_MONK_FLYING_SERPENT_KICK_AOE                  = 123586,
    SPELL_MONK_FLYING_SERPENT_KICK_NEW                  = 115057,
    SPELL_MONK_FORTIFYING_BREW                          = 120954,
    SPELL_MONK_GIFT_OF_THE_OX_AURA                      = 124502,
    SPELL_MONK_GIFT_OF_THE_OX_AT_RIGHT                  = 124503,
    SPELL_MONK_GIFT_OF_THE_OX_AT_LEFT                   = 124506,
    SPELL_MONK_GLYPH_OF_BLACKOUT_KICK                   = 132005,
    SPELL_MONK_GLYPH_OF_RENEWING_MIST                   = 123334,
    SPELL_MONK_GLYPH_OF_ZEN_FLIGHT                      = 125893,
    SPELL_MONK_GRAPPLE_WEAPON_DPS_UPGRADE               = 123231,
    SPELL_MONK_GRAPPLE_WEAPON_HEAL_UPGRADE              = 123234,
    SPELL_MONK_GRAPPLE_WEAPON_TANK_UPGRADE              = 123232,
    SPELL_MONK_GUARD                                    = 115295,
    SPELL_MONK_HEALING_ELIXIRS_AURA                     = 122280,
    SPELL_MONK_HEALING_ELIXIRS_RESTORE_HEALTH           = 122281,
    SPELL_MONK_HEAVY_STAGGER                            = 124273,
    SPELL_MONK_ITEM_2_S12_MISTWEAVER                    = 131561,
    SPELL_MONK_ITEM_4_S12_MISTWEAVER                    = 124487,
    SPELL_MONK_ITEM_PVP_GLOVES_BONUS                    = 124489,
    SPELL_MONK_JADE_LIGHTNING_ENERGIZE                  = 123333,
    SPELL_MONK_KEG_SMASH_AURA                           = 121253,
    SPELL_MONK_KEG_SMASH_ENERGIZE                       = 127796,
    SPELL_MONK_KEG_SMASH_VISUAL                         = 123662,
    SPELL_MONK_LEGACY_OF_THE_EMPEROR                    = 117667,
    SPELL_MONK_LIFECYCLES_ENVELOPING_MIST               = 197919,
    SPELL_MONK_LIFECYCLES_VIVIFY                        = 197916,
    SPELL_MONK_LIGHT_STAGGER                            = 124275,
    SPELL_MONK_MANA_TEA_REGEN                           = 115294,
    SPELL_MONK_MANA_TEA_STACKS                          = 115867,
    SPELL_MONK_MEDITATE_VISUAL                          = 124416,
    SPELL_MONK_MODERATE_STAGGER                         = 124274,
    SPELL_MONK_MORTAL_WOUNDS                            = 115804,
    SPELL_MONK_PATH_OF_BLOSSOM_AREATRIGGER              = 122035,
    SPELL_MONK_PLUS_ONE_MANA_TEA                        = 123760,
    SPELL_MONK_POWER_STRIKES_TALENT                     = 121817,
    SPELL_MONK_POWER_STRIKES_AURA                       = 129914,
    SPELL_MONK_PROVOKE                                  = 118635,
    SPELL_MONK_PROVOKE_AOE                              = 118635,
    SPELL_MONK_PROVOKE_SINGLE_TARGET                    = 116189,
    SPELL_MONK_PURIFYING_BREW                           = 119582,
    SPELL_MONK_COUNTERACT_MAGIC                         = 202428,
    SPELL_MONK_RENEWING_MIST                            = 115151,
    SPELL_MONK_RENEWING_MIST_HOT                        = 119611,
    SPELL_MONK_RENEWING_MIST_JUMP                       = 119607,
    SPELL_MONK_VISUAL_RENEWING_MIST                     = 24599,
    SPELL_MONK_RING_OF_PEACE_DISARM                     = 137461,
    SPELL_MONK_RING_OF_PEACE_SILENCE                    = 137460,
    SPELL_MONK_RISING_SUN_KICK                          = 107428,
    SPELL_MONK_RISING_THUNDER                           = 210804,
    SPELL_MONK_ROLL                                     = 109132,
    SPELL_MONK_ROLL_ANIMATION                           = 111396,
    SPELL_MONK_ROLL_BACKWARD                            = 109131,
    SPELL_MONK_ROLL_TRIGGER                             = 107427,
    SPELL_MONK_SHUFFLE                                  = 115307,
    SPELL_MONK_SONG_OF_CHIJI                            = 198909,
    SPELL_MONK_SOOTHING_MIST                            = 115175,
    SPELL_MONK_SOOTHING_MIST_AURA                       = 193884,
    SPELL_MONK_SOOTHING_MIST_ENERGIZE                   = 116335,
    SPELL_MONK_SOOTHING_MIST_VISUAL                     = 125955,
    SPELL_MONK_SPEAR_HAND_STRIKE_SILENCE                = 116709,
    SPELL_MONK_SPINNING_FIRE_BLOSSOM_MISSILE            = 118852,
    SPELL_MONK_SPINNING_FIRE_BLOSSOM_ROOT               = 123407,
    SPELL_MONK_SPIRIT_OF_THE_CRANE_AURA                 = 210802,
    SPELL_MONK_SPIRIT_OF_THE_CRANE_MANA                 = 210803,
    SPELL_MONK_STAGGER                                  = 124255,
    SPELL_MONK_STANCE_OF_THE_SPIRITED_CRANE             = 154436,
    SPELL_MONK_SURGING_MIST_HEAL                        = 116995,
    SPELL_MONK_TEACHINGS_OF_THE_MONASTERY               = 202090,
    SPELL_MONK_TEACHINGS_OF_THE_MONASTERY_PASSIVE       = 116645,
    SPELL_MONK_TIGER_PALM                               = 100780,
    SPELL_MONK_THUNDER_FOCUS_TEA                        = 116680,
    SPELL_MONK_TIGEREYE_BREW                            = 116740,
    SPELL_MONK_TIGEREYE_BREW_STACKS                     = 125195,
    SPELL_MONK_TRANSCENDENCE_CLONE_TARGET               = 119051,
    SPELL_MONK_TRANSCENDENCE_VISUAL                     = 119053,
    SPELL_MONK_TOUCH_OF_DEATH                           = 115080,
    SPELL_MONK_TOUCH_OF_DEATH_DAMAGE                    = 229980,
    SPELL_MONK_TOUCH_OF_DEATH_AMPLIFIER                 = 271232,
    SPELL_MONK_TOUCH_OF_KARMA                           = 122470,
    SPELL_MONK_TOUCH_OF_KARMA_BUFF                      = 125174,
    SPELL_MONK_TOUCH_OF_KARMA_DAMAGE                    = 124280,
    SPELL_MONK_UPLIFT_ALLOWING_CAST                     = 123757,
    SPELL_MONK_VIVIFY                                   = 116670,
    SPELL_MONK_WAY_OF_THE_CRANE                         = 216113,
    SPELL_MONK_WAY_OF_THE_CRANE_HEAL                    = 216161,
    SPELL_MONK_WEAKENED_BLOWS                           = 115798,
    SPELL_MONK_WHIRLING_DRAGON_PUNCH                    = 152175,
    SPELL_MONK_WHIRLING_DRAGON_PUNCH_CASTER_AURA        = 196742,
    SPELL_MONK_WHIRLING_DRAGON_PUNCH_DAMAGE             = 158221,
    SPELL_MONK_WINDWALKER_AURA                          = 166646,
    SPELL_MONK_WINDWALKING                              = 157411,
    SPELL_MONK_XUEN_AURA                                = 123999,
    SPELL_MONK_ZEN_FLIGHT                               = 125883,
    SPELL_MONK_ZEN_FOCUS                                = 124488,
    SPELL_MONK_ZEN_PILGRIMAGE                           = 126892,
    SPELL_MONK_ZEN_PILGRIMAGE_RETURN                    = 126895,
    SPELL_MONK_ZEN_PILGREIMAGE_RETURN_AURA              = 126896,
    SPELL_MONK_ZEN_PULSE_DAMAGE                         = 124081,
    SPELL_MONK_ZEN_PULSE_HEAL                           = 198487,
    SPELL_SERPENT_STATUE_SOOTHING_MIST                  = 248887,
    SPELL_MONK_RING_OF_PEACE_KNOCKBACK                  = 142895,
    SPELL_MONK_MYSTIC_TOUCH                             = 8647,
    SPELL_MONK_MYSTIC_TOUCH_TARGET_DEBUFF               = 113746,
    SPELL_MONK_ESSENCE_FONT                             = 191837,
    SPELL_MONK_ESSENCE_FONT_PERIODIC_HEAL               = 191840,
    SPELL_RISING_MIST                                   = 274909,
    SPELL_RISING_MIST_HEAL                              = 274912,
    SPELL_MONK_FISTS_OF_FURY_STUN                       = 120086,
    SPELL_MONK_GOOD_KARMA                               = 280195,
    SPELL_MONK_CHI_WAVE_TARGET_SELECTOR                 = 132466,
    SPELL_MONK_IRONSKIN_BREW_BUFF                       = 215479,
    SPELL_MONK_FORTIFYING_BREW_CAST                     = 115203,
    SPELL_MONK_FORTIFYING_BREW_MW                       = 243435,
    SPELL_MONK_BLACKOUT_COMBO                           = 196736,
    SPELL_MONK_BLACKOUT_COMBO_BUFF                      = 228563,
    SPELL_MONK_BOB_AND_WEAVE                            = 280515,
    SPELL_MONK_HIGH_TOLERANCE                           = 196737,
    SPELL_MONK_COMBO_BREAKER                            = 137384,
    SPELL_MONK_SPINNING_CRANE_KICK                      = 101546,
    SPELL_MONK_SPINNING_CRANE_KICK_DAMAGE               = 107270,
    SPELL_MONK_CYCLONE_STRIKES                          = 220357,
    SPELL_MONK_CYCLONE_STRIKES_BUFF                     = 220358,
    SPELL_MONK_MARK_OF_THE_CRANE                        = 228287,
    SPELL_MONK_SERENITY                                 = 152173,
    SPELL_MONK_FIST_OF_THE_WHITE_TIGER                  = 261947,
    SPELL_MONK_RUSHING_JADE_WIND                        = 116847,
    SPELL_MONK_RUSHING_JADE_WIND_DAMAGE                 = 148187,
    SPELL_MONK_RUSHING_JADE_WIND_MW                     = 196725,
    SPELL_MONK_RUSHING_JADE_WIND_MW_DAMAGE              = 162530,
    SPELL_MONK_HIT_COMBO                                = 196740,
    SPELL_MONK_HIT_COMBO_BUFF                           = 196741,
    SPELL_MONK_INNER_STRENGTH                           = 261767,
    SPELL_MONK_INNER_STRENGTH_BUFF                       = 261769,
    SPELL_MONK_SPIRITUAL_FOCUS                           = 280197,
    SPELL_MONK_XUEN                                     = 123904,
    SPELL_MONK_MANA_TEA_BFA                             = 197908,
    SPELL_MONK_CHI_JI                                   = 198664,
    SPELL_MONK_CHI_JI_HEAL                              = 198756,
    SPELL_MONK_REVIVAL                                  = 115310,
    SPELL_MONK_UPWELLING                                = 274963,
    SPELL_MONK_FOCUSED_THUNDER                          = 197895,
    SPELL_MONK_TFT_ENVELOP_HEAL                         = 274062,
    SPELL_MONK_EXPEL_HARM_DAMAGE                        = 115129,
};

enum StormEarthAndFireSpells
{
    SPELL_MONK_SEF                  = 137639,
    SPELL_MONK_SEF_STORM_VISUAL     = 138080,
    SPELL_MONK_SEF_FIRE_VISUAL      = 138081,
    SPELL_MONK_SEF_EARTH_VISUAL     = 138083,
    SPELL_MONK_SEF_CHARGE           = 138104,
    SPELL_MONK_SEF_SUMMON_EARTH     = 138121,
    SPELL_MONK_SEF_SUMMON_FIRE      = 138123,
    SPELL_MONK_SEF_SUMMONS_STATS    = 138130,
    SPELL_MONK_SEF_CHARGE_TARGET    = 196860,
    SPELL_MONK_SEF_FIXATE           = 221771,

    NPC_FIRE_SPIRIT                 = 69791,
    NPC_EARTH_SPIRIT                = 69792,
};

#define MONK_TRANSCENDENCE_GUID "MONK_TRANSCENDENCE_GUID"

// 109132 - Roll
class spell_monk_roll : public SpellScriptLoader
{
public:
    spell_monk_roll() : SpellScriptLoader("spell_monk_roll") { }

    class spell_monk_roll_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_roll_SpellScript);

    private:
        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_ROLL) ||
                !sSpellMgr->GetSpellInfo(SPELL_MONK_ROLL_TRIGGER) ||
                !sSpellMgr->GetSpellInfo(SPELL_MONK_ROLL_BACKWARD))
                return false;
            return true;
        }

        void HandleAfterCast()
        {
            Unit* caster = GetCaster();
            if (!caster || caster->GetTypeId() != TYPEID_PLAYER)
                return;

            if (caster->HasAura(SPELL_MONK_ITEM_PVP_GLOVES_BONUS))
                caster->RemoveAurasByType(SPELL_AURA_MOD_DECREASE_SPEED);
        }

        void HandleDummy()
        {
            if (Unit* caster = GetCaster())
            {
                if (caster->HasUnitMovementFlag(MOVEMENTFLAG_BACKWARD))
                    caster->CastSpell(caster, SPELL_MONK_ROLL_BACKWARD, true);
                else
                    caster->CastSpell(caster, SPELL_MONK_ROLL_TRIGGER, true);
            }
        }

        void Register() override
        {
            AfterCast += SpellCastFn(spell_monk_roll_SpellScript::HandleAfterCast);
            AfterHit += SpellHitFn(spell_monk_roll_SpellScript::HandleDummy);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_roll_SpellScript();
    }
};

// Roll trigger - 107427
class spell_monk_roll_trigger : public SpellScriptLoader
{
public:
    spell_monk_roll_trigger() : SpellScriptLoader("spell_monk_roll_trigger") {}

    class spell_monk_roll_trigger_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_roll_trigger_AuraScript);

        void CalcSpeed(AuraEffect const* /*aurEff*/, int32& amount, bool& /*canBeRecalculated*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            if (caster->HasAura(SPELL_MONK_ENHANCED_ROLL))
                amount = 277;
        }

        void CalcSpeed2(AuraEffect const* /*aurEff*/, int32& amount, bool& /*canBeRecalculated*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            if (!caster->HasAura(SPELL_MONK_ENHANCED_ROLL))
                return;

            amount = 377;
        }

        void SendAmount(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            if (!caster->HasAura(SPELL_MONK_ENHANCED_ROLL))
                return;

            Aura* aur = GetAura();
            if (!aur)
                return;

            aur->SetMaxDuration(600);
            aur->SetDuration(600);

            if (AuraApplication* aurApp = GetAura()->GetApplicationOfTarget(caster->GetGUID()))
                aurApp->ClientUpdate();
        }

        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_roll_trigger_AuraScript::CalcSpeed, EFFECT_0, SPELL_AURA_MOD_SPEED_NO_CONTROL);
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_roll_trigger_AuraScript::CalcSpeed2, EFFECT_2, SPELL_AURA_MOD_MINIMUM_SPEED);
            AfterEffectApply += AuraEffectApplyFn(spell_monk_roll_trigger_AuraScript::SendAmount, EFFECT_4, SPELL_AURA_USE_NORMAL_MOVEMENT_SPEED, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_roll_trigger_AuraScript();
    }
};

// Fists of Fury (stun effect) - 120086
class spell_monk_fists_of_fury_stun : public SpellScriptLoader
{
public:
    spell_monk_fists_of_fury_stun() : SpellScriptLoader("spell_monk_fists_of_fury_stun") { }

    class spell_monk_fists_of_fury_stun_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_fists_of_fury_stun_SpellScript);

        void RemoveInvalidTargets(std::list<WorldObject*>& targets)
        {
            targets.remove_if(Trinity::UnitAuraCheck(true, GetSpellInfo()->Id));
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_fists_of_fury_stun_SpellScript::RemoveInvalidTargets, EFFECT_0, TARGET_UNIT_CONE_ENEMY_24);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_fists_of_fury_stun_SpellScript();
    }
};

// Expel Harm - 115072
class spell_monk_expel_harm : public SpellScriptLoader
{
public:
    spell_monk_expel_harm() : SpellScriptLoader("spell_monk_expel_harm") { }

    class spell_monk_expel_harm_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_expel_harm_SpellScript);

        void HandleOnHit()
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            Player* player = caster->ToPlayer();
            if (!player)
                return;

            SpellEffectInfo const* dummy10 = GetSpellInfo()->GetEffect(EFFECT_1);
            if (!dummy10)
                return;

            int32 healAmt = GetHitHeal();
            if (healAmt <= 0)
                healAmt = -GetHitDamage();
            if (healAmt <= 0)
                return;

            int32 pct = dummy10->CalcValue(caster);
            int32 bp = CalculatePct(healAmt, pct);

            float range = 8.0f;
            if (SpellInfo const* dmgInfo = sSpellMgr->GetSpellInfo(SPELL_MONK_EXPEL_HARM_DAMAGE))
                range = dmgInfo->GetMaxRange(false, caster);

            std::list<Unit*> targetList;
            player->GetAttackableUnitListInRange(targetList, range);

            Unit* nearest = nullptr;
            float nearestDist = range;
            for (Unit* unit : targetList)
            {
                if (!player->IsValidAttackTarget(unit))
                    continue;
                float dist = player->GetDistance(unit);
                if (dist <= nearestDist)
                {
                    nearestDist = dist;
                    nearest = unit;
                }
            }

            if (nearest)
                player->CastCustomSpell(nearest, SPELL_MONK_EXPEL_HARM_DAMAGE, &bp, nullptr, nullptr, true);
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_expel_harm_SpellScript::HandleOnHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_expel_harm_SpellScript();
    }
};

// Chi Wave (healing bolt) - 132464
class spell_monk_chi_wave_healing_bolt : public SpellScriptLoader
{
public:
    spell_monk_chi_wave_healing_bolt() : SpellScriptLoader("spell_monk_chi_wave_healing_bolt") { }

    class spell_monk_chi_wave_healing_bolt_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_chi_wave_healing_bolt_SpellScript);

        void HandleOnHit()
        {
            if (!GetOriginalCaster())
                return;

            if (Player* _player = GetOriginalCaster()->ToPlayer())
                if (Unit* target = GetHitUnit())
                    _player->CastSpell(target, SPELL_MONK_CHI_WAVE_HEAL, true);
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_chi_wave_healing_bolt_SpellScript::HandleOnHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_chi_wave_healing_bolt_SpellScript();
    }
};

// 132464 - Chi Wave (heal missile)
class spell_monk_chi_wave_heal_missile : public SpellScriptLoader
{
public:
    spell_monk_chi_wave_heal_missile() : SpellScriptLoader("spell_monk_chi_wave_heal_missile") {}

    class spell_monk_chi_wave_heal_missile_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_chi_wave_heal_missile_AuraScript);

        void OnRemove(AuraEffect const* aurEff, AuraEffectHandleModes /*mode*/)
        {
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            if (!target || !caster)
                return;

            caster->CastSpell(target, 132463, true);
            // rerun target selector
            caster->CastCustomSpell(132466, SPELLVALUE_BASE_POINT1, aurEff->GetAmount() - 1, target, true, NULL, aurEff);
        }

        void Register() override
        {
            OnEffectRemove += AuraEffectRemoveFn(spell_monk_chi_wave_heal_missile_AuraScript::OnRemove, EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_chi_wave_heal_missile_AuraScript();
    }
};

// 132467 - Chi Wave (damage missile)
class spell_monk_chi_wave_damage_missile : public SpellScriptLoader
{
public:
    spell_monk_chi_wave_damage_missile() : SpellScriptLoader("spell_monk_chi_wave_damage_missile") {}

    class spell_monk_chi_wave_damage_missile_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_chi_wave_damage_missile_AuraScript);

        void OnRemove(AuraEffect const* aurEff, AuraEffectHandleModes /*mode*/)
        {
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            if (!target || !caster)
                return;

            // rerun target selector
            caster->CastCustomSpell(132466, SPELLVALUE_BASE_POINT1, aurEff->GetAmount() - 1, target, true, NULL, aurEff);
        }

        void Register() override
        {
            OnEffectRemove += AuraEffectRemoveFn(spell_monk_chi_wave_damage_missile_AuraScript::OnRemove, EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_chi_wave_damage_missile_AuraScript();
    }
};

// Called by Thunder Focus Tea - 116680
// Item S12 4P - Mistweaver - 124487
class spell_monk_item_s12_4p_mistweaver : public SpellScriptLoader
{
public:
    spell_monk_item_s12_4p_mistweaver() : SpellScriptLoader("spell_monk_item_s12_4p_mistweaver") { }

    class spell_monk_item_s12_4p_mistweaver_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_item_s12_4p_mistweaver_SpellScript);

        void HandleOnHit()
        {
            if (Player* _player = GetCaster()->ToPlayer())
                if (_player->HasAura(SPELL_MONK_ITEM_4_S12_MISTWEAVER))
                    _player->CastSpell(_player, SPELL_MONK_ZEN_FOCUS, true);
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_item_s12_4p_mistweaver_SpellScript::HandleOnHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_item_s12_4p_mistweaver_SpellScript();
    }
};

// Diffuse Magic - 122783
// En attente

// Summon Black Ox Statue - 115315
// En attente

// Bear Hug - 127361
// En attente

// Zen Flight - 125883
class spell_monk_zen_flight_check : public SpellScriptLoader
{
public:
    spell_monk_zen_flight_check() : SpellScriptLoader("spell_monk_zen_flight_check") { }

    class spell_monk_zen_flight_check_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_zen_flight_check_SpellScript);

        SpellCastResult CheckTarget()
        {
            if (Player* _player = GetCaster()->ToPlayer())
            {
                if (_player->GetMap()->IsBattlegroundOrArena())
                    return SPELL_FAILED_NOT_IN_BATTLEGROUND;

                // In Kalimdor or Eastern Kingdom with Flight Master's License
                if (!_player->HasSpell(90267) && (_player->GetMapId() == 1 || _player->GetMapId() == 0))
                    return SPELL_FAILED_NOT_HERE;

                // In Pandaria with Wisdom of the Four Winds
                if (!_player->HasSpell(115913) && (_player->GetMapId() == 870))
                    return SPELL_FAILED_NOT_HERE;

                // Legion, Broken Isles
                if (_player->GetMapId() == 1220)
                    return SPELL_FAILED_NOT_HERE;

                // In BfA Content not yet
                if (_player->GetMapId() == 1642 || _player->GetMapId() == 1643)
                    return SPELL_FAILED_NOT_HERE;
            }

            return SPELL_CAST_OK;
        }

        void Register() override
        {
            OnCheckCast += SpellCheckCastFn(spell_monk_zen_flight_check_SpellScript::CheckTarget);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_zen_flight_check_SpellScript();
    }

    class spell_monk_zen_flight_check_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_zen_flight_check_AuraScript);

        bool Load() override
        {
            return GetCaster() && GetCaster()->GetTypeId() == TYPEID_PLAYER;
        }

        void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool & /*canBeRecalculated*/)
        {
            if (!GetCaster())
                return;

            if (Player* caster = GetCaster()->ToPlayer())
                if (caster->GetSkillValue(SKILL_RIDING) >= 375)
                    amount = 310;
        }

        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_zen_flight_check_AuraScript::CalculateAmount, EFFECT_1, SPELL_AURA_MOD_INCREASE_VEHICLE_FLIGHT_SPEED);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_zen_flight_check_AuraScript();
    }
};

// Glyph of Zen Flight - 125893
// En attente

// Called by Jab - 100780
// Power Strikes - 121817
// En attente

// Crackling Jade Lightning - 117952
class spell_monk_crackling_jade_lightning : public SpellScriptLoader
{
public:
    spell_monk_crackling_jade_lightning() : SpellScriptLoader("spell_monk_crackling_jade_lightning") { }

    class spell_monk_crackling_jade_lightning_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_crackling_jade_lightning_AuraScript);

        void OnProc(AuraEffect const* /* aurEff */, ProcEventInfo& eventInfo)
        {
            PreventDefaultAction();

            if (!GetCaster())
                return;

            if (eventInfo.GetActor()->GetGUID() != GetTarget()->GetGUID())
                return;

            /*if (GetCaster()->ToPlayer())
            {
                ;
            }*/
        }

        void Register() override
        {
            OnEffectProc += AuraEffectProcFn(spell_monk_crackling_jade_lightning_AuraScript::OnProc, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_crackling_jade_lightning_AuraScript();
    }
};

// Touch of Karma - 122470
// En attente

// Path of Blossom - 124336
class spell_monk_path_of_blossom : public AuraScript
{
    PrepareAuraScript(spell_monk_path_of_blossom);

    void OnTick(AuraEffect const* /* aurEff */)
    {
        if (GetCaster())
            GetCaster()->CastSpell(GetCaster(), SPELL_MONK_PATH_OF_BLOSSOM_AREATRIGGER, true);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_path_of_blossom::OnTick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// Called by Uplift - 116670 and Uplift - 130316
// Thunder Focus Tea - 116680
// En attente

// Summon Jade Serpent Statue - 115313
// En attente

class spell_monk_mana_tea : public SpellScriptLoader
{
public:
    spell_monk_mana_tea() : SpellScriptLoader("spell_monk_mana_tea") { }

    class spell_monk_mana_tea_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_mana_tea_SpellScript);

        void Register() override
        {
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_mana_tea_SpellScript();
    }

    class spell_monk_mana_tea_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_mana_tea_AuraScript);

        void Register() override
        {
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_mana_tea_AuraScript();
    }
};

// Brewing : Mana Tea - 123766
class spell_monk_mana_tea_stacks : public SpellScriptLoader
{
public:
    spell_monk_mana_tea_stacks() : SpellScriptLoader("spell_monk_mana_tea_stacks") { }

    class spell_monk_mana_tea_stacks_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_mana_tea_stacks_AuraScript);

        uint32 chiConsumed;

        void OnApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            chiConsumed = 0;
        }

        void SetData(uint32 /* type */, uint32 data)
        {
            while ((chiConsumed += data) >= 4)
            {
                chiConsumed = 0;
                data = data > 4 ? data - 4 : 0;

                if (GetCaster())
                {
                    GetCaster()->CastSpell(GetCaster(), SPELL_MONK_MANA_TEA_STACKS, true);
                    GetCaster()->CastSpell(GetCaster(), SPELL_MONK_PLUS_ONE_MANA_TEA, true);
                }
            }
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_monk_mana_tea_stacks_AuraScript::OnApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_mana_tea_stacks_AuraScript();
    }
};

// Enveloping Mist - 124682
class spell_monk_enveloping_mist : public SpellScriptLoader
{
public:
    spell_monk_enveloping_mist() : SpellScriptLoader("spell_monk_enveloping_mist") { }

    class spell_monk_enveloping_mist_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_enveloping_mist_SpellScript);

        void HandleOnPrepare()
        {
            if (GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL) && GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL)->GetSpellInfo()->Id == SPELL_MONK_SOOTHING_MIST)
            {
                TriggerCastFlags castFlags = TriggerCastFlags(GetSpell()->GetTriggeredCastFlags() | TRIGGERED_CAST_DIRECTLY);
                GetSpell()->SetTriggerCastFlags(castFlags);
                SpellCastTargets targets = GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL)->m_targets;
                GetSpell()->InitExplicitTargets(targets);
            }
        }

        void Register() override
        {
            OnPrepare += SpellOnPrepareFn(spell_monk_enveloping_mist_SpellScript::HandleOnPrepare);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_enveloping_mist_SpellScript();
    }
};

// Renewing Mist - 119611
// En attente

// Called by : Fortifying Brew - 115203, Chi Brew - 115399, Elusive Brew - 115308, Tigereye Brew - 116740
// Purifying Brew - 119582, Mana Tea - 115294, Thunder Focus Tea - 116680 and Energizing Brew - 115288
// Healing Elixirs - 122280
// En attente

// Zen Pulse - 124081
class spell_monk_zen_pulse : public SpellScriptLoader
{
public:
    spell_monk_zen_pulse() : SpellScriptLoader("spell_monk_zen_pulse") {}

    class spell_monk_zen_pulse_SpellScript : public SpellScript
    {

        PrepareSpellScript(spell_monk_zen_pulse_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_ZEN_PULSE_DAMAGE))
                return false;
            return true;
        }

        void OnHit(SpellEffIndex /*effIndex*/)
        {
            GetCaster()->CastSpell(GetCaster(), SPELL_MONK_ZEN_PULSE_HEAL, true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_zen_pulse_SpellScript::OnHit, EFFECT_1, SPELL_EFFECT_SCHOOL_DAMAGE);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_zen_pulse_SpellScript();
    }
};

// Chi Burst - 123986
// En attente

// Energizing Brew - 115288
class spell_monk_energizing_brew : public SpellScriptLoader
{
public:
    spell_monk_energizing_brew() : SpellScriptLoader("spell_monk_energizing_brew") { }

    class spell_monk_energizing_brew_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_energizing_brew_SpellScript);

        SpellCastResult CheckFight()
        {
            if (!GetCaster()->IsInCombat())
                return SPELL_FAILED_CASTER_AURASTATE;
            return SPELL_CAST_OK;
        }

        void Register() override
        {
            OnCheckCast += SpellCheckCastFn(spell_monk_energizing_brew_SpellScript::CheckFight);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_energizing_brew_SpellScript();
    }
};

// Spear Hand Strike - 116705
// En attente

// Tigereye Brew - 116740
// En attente

// Tiger's Lust - 116841
// En attente

// Flying Serpent Kick - 115057
class spell_monk_flying_serpent_kick : public SpellScriptLoader
{
public:
    spell_monk_flying_serpent_kick() : SpellScriptLoader("spell_monk_flying_serpent_kick") { }

    class spell_monk_flying_serpent_kick_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_flying_serpent_kick_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_FLYING_SERPENT_KICK_NEW))
                return false;
            return true;
        }

        void HandleOnCast()
        {
            if (Unit* caster = GetCaster())
            {
                if (Player* _player = caster->ToPlayer())
                {
                    if (_player->HasAura(SPELL_MONK_FLYING_SERPENT_KICK))
                        _player->RemoveAura(SPELL_MONK_FLYING_SERPENT_KICK);

                    if (caster->HasAura(SPELL_MONK_ITEM_PVP_GLOVES_BONUS))
                        caster->RemoveAurasByType(SPELL_AURA_MOD_DECREASE_SPEED);

                    _player->CastSpell(_player, SPELL_MONK_FLYING_SERPENT_KICK_AOE, true);
                }
            }
        }

        void Register() override
        {
            OnCast += SpellCastFn(spell_monk_flying_serpent_kick_SpellScript::HandleOnCast);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_flying_serpent_kick_SpellScript();
    }
};

// Chi Torpedo - 115008 or Chi Torpedo (3 charges) - 121828
// En attente

// Purifying Brew - 119582
class spell_monk_purifying_brew : public SpellScriptLoader
{
public:
    spell_monk_purifying_brew() : SpellScriptLoader("spell_monk_purifying_brew") { }

    class spell_monk_purifying_brew_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_purifying_brew_SpellScript);

        void HandleOnHit()
        {
            if (Unit* caster = GetCaster())
            {
                if (Player* _player = caster->ToPlayer())
                {
                    Aura* staggerAmount = _player->GetAura(SPELL_MONK_LIGHT_STAGGER);

                    if (!staggerAmount)
                        staggerAmount = _player->GetAura(SPELL_MONK_MODERATE_STAGGER);
                    if (!staggerAmount)
                        staggerAmount = _player->GetAura(SPELL_MONK_HEAVY_STAGGER);

                    if (staggerAmount)
                    {
                        SpellEffectInfo const* dummy50 = GetSpellInfo()->GetEffect(EFFECT_0);
                        if (!dummy50)
                            return;
                        int32 purifyPct = dummy50->CalcValue(caster);

                        auto Purify = [purifyPct](int32 amount) -> int32
                        {
                            return amount - CalculatePct(amount, purifyPct);
                        };

                        if (AuraEffect* visualTotal = staggerAmount->GetEffect(EFFECT_1))
                            visualTotal->ChangeAmount(Purify(visualTotal->GetAmount()));
                        if (AuraEffect* visualTick = staggerAmount->GetEffect(EFFECT_0))
                            visualTick->ChangeAmount(Purify(visualTick->GetAmount()));
                        if (Aura* staggerDot = _player->GetAura(SPELL_MONK_STAGGER))
                            if (AuraEffect* tick = staggerDot->GetEffect(EFFECT_0))
                                tick->ChangeAmount(Purify(tick->GetAmount()));
                    }
                }
            }
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_purifying_brew_SpellScript::HandleOnHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_purifying_brew_SpellScript();
    }
};

// Keg Smash - 121253
class spell_monk_keg_smash : public SpellScriptLoader
{
public:
    spell_monk_keg_smash() : SpellScriptLoader("spell_monk_keg_smash") { }

    class spell_monk_keg_smash_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_keg_smash_SpellScript);

        void HandleOnHit()
        {
            if (Unit* caster = GetCaster())
            {
                if (Player* _player = caster->ToPlayer())
                {
                    if (Unit* target = GetHitUnit())
                    {
                        _player->CastSpell(target, SPELL_MONK_KEG_SMASH_VISUAL, true);

                        int32 dummy4 = 0;
                        if (SpellEffectInfo const* dummy = GetSpellInfo()->GetEffect(EFFECT_3))
                            dummy4 = dummy->CalcValue(caster);
                        if (dummy4)
                        {
                            int32 reduce = -dummy4 * IN_MILLISECONDS;
                            _player->GetSpellHistory()->ModifyCooldown(SPELL_MONK_ELUSIVE_BREW, reduce);
                            _player->GetSpellHistory()->ModifyCooldown(SPELL_MONK_PURIFYING_BREW, reduce);
                        }

                        if (_player->HasAura(SPELL_MONK_BLACKOUT_COMBO_BUFF))
                        {
                            if (SpellInfo const* combo = sSpellMgr->GetSpellInfo(SPELL_MONK_BLACKOUT_COMBO))
                                if (SpellEffectInfo const* dummy2 = combo->GetEffect(EFFECT_2))
                                {
                                    int32 extra = -dummy2->CalcValue(_player) * IN_MILLISECONDS;
                                    _player->GetSpellHistory()->ModifyCooldown(SPELL_MONK_ELUSIVE_BREW, extra);
                                    _player->GetSpellHistory()->ModifyCooldown(SPELL_MONK_PURIFYING_BREW, extra);
                                }
                            _player->RemoveAura(SPELL_MONK_BLACKOUT_COMBO_BUFF);
                        }
                    }
                }
            }
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_keg_smash_SpellScript::HandleOnHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_keg_smash_SpellScript();
    }
};

// Elusive Brew - 115308
// En attente

// Soothing Mist - 115175
class spell_monk_soothing_mist : public SpellScriptLoader
{
public:
    spell_monk_soothing_mist() : SpellScriptLoader("spell_monk_soothing_mist") { }

    class spell_monk_soothing_mist_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_soothing_mist_AuraScript);

        void OnApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            if (!GetCaster())
                return;

            if (Unit* target = GetTarget())
                target->CastSpell(target, SPELL_MONK_SOOTHING_MIST_VISUAL, true);

            if (Player* player = GetCaster()->ToPlayer())
            {
                if (Unit* target = GetTarget())
                {
                    std::list<Unit*> playerList;
                    std::list<Creature*> tempList;
                    std::list<Creature*> statueList;
                    Creature* statue = nullptr;

                    player->GetPartyMembers(playerList);

                    if (playerList.size() > 1)
                    {
                        playerList.remove(target);
                        playerList.sort(Trinity::HealthPctOrderPred());
                        playerList.resize(1);
                    }

                    player->GetCreatureListWithEntryInGrid(tempList, 60849, 100.0f);
                    player->GetCreatureListWithEntryInGrid(statueList, 60849, 100.0f);

                    for (std::list<Creature*>::iterator i = tempList.begin(); i != tempList.end(); ++i)
                    {
                        Unit* owner = (*i)->GetOwner();
                        if (owner && owner == player && (*i)->IsSummon())
                            continue;

                        statueList.remove((*i));
                    }

                    for ([[maybe_unused]] auto itr : playerList)
                    {
                        if (statueList.size() == 1)
                        {
                            for (auto itrBis : statueList)
                                statue = itrBis;
     
                            if (statue->GetOwner() && statue->GetOwner()->GetGUID() == player->GetGUID())
                            {
                                if (statue->GetOwner() && statue->GetOwner()->GetGUID() == player->GetGUID())
                                    statue->CastSpell(statue->GetOwner()->ToPlayer()->GetSelectedUnit(), SPELL_SERPENT_STATUE_SOOTHING_MIST, false);
                            }
                        }
                    }
                }
            }
        }

        void OnRemove(AuraEffect const* /* aurEff */, AuraEffectHandleModes /*mode*/)
        {
            if (GetCaster())
                if (Unit* target = GetTarget())
                    if (target->HasAura(SPELL_MONK_SOOTHING_MIST_VISUAL))
                        target->RemoveAura(SPELL_MONK_SOOTHING_MIST_VISUAL);
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_monk_soothing_mist_AuraScript::OnApply, EFFECT_0, SPELL_AURA_PERIODIC_HEAL, AURA_EFFECT_HANDLE_REAL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_monk_soothing_mist_AuraScript::OnRemove, EFFECT_0, SPELL_AURA_PERIODIC_HEAL, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_soothing_mist_AuraScript();
    }
};

// Disable - 116095
class spell_monk_disable : public SpellScript
{
    PrepareSpellScript(spell_monk_disable);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_DISABLE, SPELL_MONK_DISABLE_ROOT });
    }

    void HandleOnEffectHitTarget(SpellEffIndex /*effectIndex*/)
    {
        if (Unit* target = GetExplTargetUnit())
            if (target->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED))
                GetCaster()->CastSpell(target, SPELL_MONK_DISABLE_ROOT, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_monk_disable::HandleOnEffectHitTarget, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
    }
};

// Disable - 116095
class aura_monk_disable : public AuraScript
{
    PrepareAuraScript(aura_monk_disable);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (DamageInfo* damageInfo = eventInfo.GetDamageInfo())
        {
            if ((damageInfo->GetAttackType() == BASE_ATTACK ||
                 damageInfo->GetAttackType() == OFF_ATTACK) &&
                damageInfo->GetAttacker() == GetCaster())
            {
                GetAura()->RefreshDuration();
                return true;
            }
        }
        return false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_monk_disable::CheckProc);
    }
};

// Zen Pilgrimage - 126892, Zen Pilgrimage - 194011
class spell_monk_zen_pilgrimage : public SpellScriptLoader
{
public:
    spell_monk_zen_pilgrimage() : SpellScriptLoader("spell_monk_zen_pilgrimage") { }

    class spell_monk_zen_pilgrimage_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_zen_pilgrimage_SpellScript);

        SpellCastResult CheckDist()
        {
            if (GetSpellInfo()->Id == 194011)
                return SPELL_CAST_OK;

            if (Unit* caster = GetCaster())
                if (Player* _player = caster->ToPlayer())
                    if (_player->IsQuestRewarded(40236)) // Check quest for port to oplot
                    {
                        caster->CastSpell(caster, 194011, false);
                        return SPELL_FAILED_DONT_REPORT;
                    }

            return SPELL_CAST_OK;
        }

        void HandleOnCast()
        {
            if (Unit* caster = GetCaster())
                if (Player* _player = caster->ToPlayer())
                {
                    _player->SaveRecallPosition();
                    _player->CastSpell(_player, 126896, true);
                }
        }

        void Register() override
        {
            OnCast += SpellCastFn(spell_monk_zen_pilgrimage_SpellScript::HandleOnCast);
            OnCheckCast += SpellCheckCastFn(spell_monk_zen_pilgrimage_SpellScript::CheckDist);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_zen_pilgrimage_SpellScript();
    }
};

// Zen Pilgrimage : Return - 126895
class spell_monk_zen_pilgrimage_return : public SpellScriptLoader
{
public:
    spell_monk_zen_pilgrimage_return() : SpellScriptLoader("spell_monk_zen_pilgrimage_return") { }

    class spell_monk_zen_pilgrimage_return_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_zen_pilgrimage_return_SpellScript);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            if (Unit* caster = GetCaster())
            {
                if (Player* _player = caster->ToPlayer())
                {
                  // _player->TeleportTo(_player->m_recallLoc); After change now iw work
                    _player->RemoveAura(126896);
                }
            }
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_zen_pilgrimage_return_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_SCRIPT_EFFECT);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_zen_pilgrimage_return_SpellScript();
    }
};

// Blackout Kick - 100784
// En attente

// Paralysis - 115078
// En attente

// Touch of Death - 115080
class spell_monk_touch_of_death : public AuraScript
{
    PrepareAuraScript(spell_monk_touch_of_death);

    void CalculateAmount(AuraEffect const* aurEff, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        if (Unit* caster = GetCaster())
            if (SpellEffectInfo const* effInfo = GetAura()->GetSpellEffectInfo(EFFECT_1))
            {
                amount = int32(caster->CountPctFromMaxHealth(effInfo->CalcValue()));
                const_cast<AuraEffect*>(aurEff)->SetDamage(amount);
            }
    }

    void OnTick(AuraEffect const* aurEff)
    {
        if (Unit* caster = GetCaster())
        {
            int32 damage = aurEff->GetAmount();

            caster->CastCustomSpell(SPELL_MONK_TOUCH_OF_DEATH_DAMAGE, SPELLVALUE_BASE_POINT0, damage, GetTarget());
        }
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_touch_of_death::CalculateAmount, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_touch_of_death::OnTick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// 271232 - Touch of Death Amplifier - Triggers: 271233 on ToD Cast via proc
class spell_monk_touch_of_death_passive : public AuraScript
{
    PrepareAuraScript(spell_monk_touch_of_death_passive);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_TOUCH_OF_DEATH
            });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (eventInfo.GetSpellInfo()->Id != SPELL_MONK_TOUCH_OF_DEATH)
            return false;
        return true;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_touch_of_death_passive::CheckProc);
    }
};

// 271233 - Amplifier (Applied with ToD)
class spell_monk_touch_of_death_amplifier : public AuraScript
{
    PrepareAuraScript(spell_monk_touch_of_death_amplifier);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_TOUCH_OF_DEATH,
                SPELL_MONK_TOUCH_OF_DEATH_AMPLIFIER
            });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return eventInfo.GetDamageInfo() && eventInfo.GetDamageInfo()->GetDamage() > 0;
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        if (AuraEffect* aurEff = GetTarget()->GetAuraEffect(SPELL_MONK_TOUCH_OF_DEATH, EFFECT_0))
            if (AuraEffect* aurEffAmplifier = eventInfo.GetActor()->GetAuraEffect(SPELL_MONK_TOUCH_OF_DEATH_AMPLIFIER, EFFECT_0))
            {
                int32 damage = aurEff->GetAmount() + CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEffAmplifier->GetAmount());
                aurEff->SetDamage(damage);
                aurEff->SetAmount(damage);
            }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_touch_of_death_amplifier::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_monk_touch_of_death_amplifier::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// Fortifying brew - 115203
class spell_monk_fortifying_brew : public SpellScriptLoader
{
public:
    spell_monk_fortifying_brew() : SpellScriptLoader("spell_monk_fortifying_brew") { }

    class spell_monk_fortifying_brew_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_fortifying_brew_SpellScript);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            if (caster && caster->GetTypeId() == TYPEID_PLAYER)
                caster->CastSpell(caster, SPELL_MONK_FORTIFYING_BREW, true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_fortifying_brew_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_fortifying_brew_SpellScript();
    }
};

// Legacy of the Emperor - 115921
class spell_monk_legacy_of_the_emperor : public SpellScriptLoader
{
public:
    spell_monk_legacy_of_the_emperor() : SpellScriptLoader("spell_monk_legacy_of_the_emperor") { }

    class spell_monk_legacy_of_the_emperor_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_legacy_of_the_emperor_SpellScript);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            if (Player* plr = GetCaster()->ToPlayer())
            {
                std::list<Unit*> groupList;

                plr->GetPartyMembers(groupList);
                if (!groupList.empty())
                    for (auto itr : groupList)
                        plr->CastSpell(itr, SPELL_MONK_LEGACY_OF_THE_EMPEROR, true);
            }
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_legacy_of_the_emperor_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_legacy_of_the_emperor_SpellScript();
    }
};

// Roll - 109132 or Roll (3 charges) - 121827
// En attente

// Brewing : Tigereye Brew - 123980
class spell_monk_tigereye_brew_stacks : public SpellScriptLoader
{
public:
    spell_monk_tigereye_brew_stacks() : SpellScriptLoader("spell_monk_tigereye_brew_stacks") { }

    class spell_monk_tigereye_brew_stacks_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_tigereye_brew_stacks_AuraScript);

        uint32 chiConsumed;

        void OnApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            chiConsumed = 0;
        }

        void SetData(uint32 /* type */, uint32 data)
        {
            while ((chiConsumed += data) >= 4)
            {
                chiConsumed = 0;
                data = data > 4 ? data - 4 : 0;

                if (GetCaster())
                    GetCaster()->CastSpell(GetCaster(), SPELL_MONK_TIGEREYE_BREW_STACKS, true);
            }
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_monk_tigereye_brew_stacks_AuraScript::OnApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_tigereye_brew_stacks_AuraScript();
    }
};

// 117959 - Crackling Jade Lightning
class spell_monk_crackling_jade_lightning_knockback_proc_aura : public SpellScriptLoader
{
public:
    spell_monk_crackling_jade_lightning_knockback_proc_aura() : SpellScriptLoader("spell_monk_crackling_jade_lightning_knockback_proc_aura") { }

    class spell_monk_crackling_jade_lightning_aura_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_crackling_jade_lightning_aura_AuraScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK))
                return false;
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK_CD))
                return false;
            return true;
        }

        bool CheckProc(ProcEventInfo& eventInfo)
        {
            Unit* target = GetTarget();

            if (target->HasAura(SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK_CD))
                return false;

            auto const& channelObjects = target->GetChannelObjects();
            if (Unit* channelTarget = (channelObjects.size() == 1 ? ObjectAccessor::GetUnit(*target, *channelObjects.begin()) : nullptr))
                if (eventInfo.GetActor()->GetGUID() != channelTarget->GetGUID())
                    return false;

            Spell* currentChanneledSpell = target->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
            if (!currentChanneledSpell || currentChanneledSpell->GetSpellInfo()->Id != SPELL_MONK_CRACKLING_JADE_LIGHTNING_CHANNEL)
                return false;

            // Dummy 200 is on 117952 EFFECT_1. 117959 only has EFFECT_0 Dummy 1 — do not GetEffect(EFFECT_1) on this aura.
            SpellInfo const* jade = sSpellMgr->GetSpellInfo(SPELL_MONK_CRACKLING_JADE_LIGHTNING_CHANNEL);
            if (!jade || !jade->GetEffect(EFFECT_1))
                return false;
            int32 chance = jade->GetEffect(EFFECT_1)->CalcValue(GetTarget()) / 10; // 200/10=20, 20 must not enter Dummy
            if (!roll_chance_i(chance))
                return false;

            return true;
        }

        void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
        {
            GetTarget()->CastSpell(eventInfo.GetActor(), SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK, TRIGGERED_FULL_MASK);
            GetTarget()->CastSpell(GetTarget(), SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCKBACK_CD, TRIGGERED_FULL_MASK);
        }

        void Register() override
        {
            DoCheckProc += AuraCheckProcFn(spell_monk_crackling_jade_lightning_aura_AuraScript::CheckProc);
            OnEffectProc += AuraEffectProcFn(spell_monk_crackling_jade_lightning_aura_AuraScript::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_crackling_jade_lightning_aura_AuraScript();
    }
};

class spell_monk_breath_of_fire : public SpellScriptLoader
{
public:
    spell_monk_breath_of_fire() : SpellScriptLoader("spell_monk_breath_of_fire") { }

    class spell_monk_breath_of_fire_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_breath_of_fire_SpellScript);

        void HandleAfterHit()
        {
            if (Unit* caster = GetCaster())
            {
                if (Player* _player = caster->ToPlayer())
                {
                    if (Unit* target = GetHitUnit())
                    {
                        if (target->HasAura(SPELL_MONK_KEG_SMASH_AURA))
                            _player->CastSpell(target, SPELL_MONK_BREATH_OF_FIRE_DOT, true);

                        if (_player->HasAura(SPELL_MONK_BLACKOUT_COMBO_BUFF))
                        {
                            if (SpellInfo const* combo = sSpellMgr->GetSpellInfo(SPELL_MONK_BLACKOUT_COMBO))
                                if (SpellEffectInfo const* dummy3 = combo->GetEffect(EFFECT_1))
                                    _player->GetSpellHistory()->ModifyCooldown(SPELL_MONK_BREATH_OF_FIRE, -dummy3->CalcValue(_player) * IN_MILLISECONDS);
                            _player->RemoveAura(SPELL_MONK_BLACKOUT_COMBO_BUFF);
                        }
                    }
                }
            }
        }

        void Register() override
        {
            AfterHit += SpellHitFn(spell_monk_breath_of_fire_SpellScript::HandleAfterHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_breath_of_fire_SpellScript();
    }
};

enum CracklingJade
{
    SPELL_MONK_CRACKLING_JADE_LIGHTNING                     = 117952,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_CHI_PROC_DRIVER     = 123332,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCK_BACK_DRIVER   = 117959,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCK_BACK          = 117962,
    SPELL_MONK_CRACKLING_JADE_LIGHTNING_TALENT              = 125648,
    SPELL_MONK_CRACKLING_JAD_LIGHTNING_TALENT_SPEED         = 125647,
};

// 117962 - crackling jade lightning knockback
class spell_monk_crackling_jade_knockback : public SpellScriptLoader
{
public:
    spell_monk_crackling_jade_knockback() : SpellScriptLoader("spell_monk_crackling_jade_knockback") { }

    class spell_monk_crackling_jade_knockback_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_crackling_jade_knockback_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return sSpellMgr->GetSpellInfo(SPELL_MONK_CRACKLING_JADE_LIGHTNING_KNOCK_BACK) != nullptr;
        }

        void Hit()
        {
            Unit* target = GetHitUnit();
            Unit* caster = GetCaster();
            if (caster && target && caster->HasAura(SPELL_MONK_CRACKLING_JADE_LIGHTNING_TALENT))
                caster->CastSpell(target, SPELL_MONK_CRACKLING_JAD_LIGHTNING_TALENT_SPEED, true);
        }

        void Register() override
        {
            AfterHit += SpellHitFn(spell_monk_crackling_jade_knockback_SpellScript::Hit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_crackling_jade_knockback_SpellScript();
    }
};

class spell_monk_power_strikes : public SpellScriptLoader
{
public:
    spell_monk_power_strikes() : SpellScriptLoader("spell_monk_power_strikes") { }

    class spell_monk_power_strikes_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_power_strikes_SpellScript);

        void HandleOnHit()
        {
            if (Player* _player = GetCaster()->ToPlayer())
            {
                if (Unit* target = GetHitUnit())
                {
                    if (target->GetGUID() != _player->GetGUID())
                    {
                        if (_player->HasAura(SPELL_MONK_POWER_STRIKES_TALENT))
                        {
                            if (!_player->GetSpellHistory()->HasCooldown(SPELL_MONK_POWER_STRIKES_TALENT))
                            {
                                if (_player->GetPower(POWER_CHI) < _player->GetMaxPower(POWER_CHI))
                                {
                                    _player->EnergizeBySpell(_player, GetSpellInfo()->Id, 1, POWER_CHI);
                                    _player->GetSpellHistory()->AddCooldown(SPELL_MONK_POWER_STRIKES_TALENT, 0, std::chrono::seconds(20));
                                }
                                else
                                    _player->CastSpell(_player, SPELL_MONK_CREATE_CHI_SPHERE, true);
                            }
                        }
                    }
                }
            }
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_power_strikes_SpellScript::HandleOnHit);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_power_strikes_SpellScript();
    }
};
// 140023 - Ring of Peace Aura
class spell_monk_ring_of_peace_aura : public SpellScriptLoader
{
public:
    spell_monk_ring_of_peace_aura() : SpellScriptLoader("spell_monk_ring_of_peace_aura") {}

    class spell_monk_ring_of_peace_aura_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_ring_of_peace_aura_AuraScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return sSpellMgr->GetSpellInfo(SPELL_MONK_RING_OF_PEACE_SILENCE)
                && sSpellMgr->GetSpellInfo(SPELL_MONK_RING_OF_PEACE_DISARM);
        }

        void HandleDummyProc(AuraEffect const* /*auraEffect*/, ProcEventInfo& /*eventInfo*/)
        {
        }

        void Register() override
        {
            OnEffectProc += AuraEffectProcFn(spell_monk_ring_of_peace_aura_AuraScript::HandleDummyProc, EFFECT_0, SPELL_AURA_DUMMY);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_ring_of_peace_aura_AuraScript();
    }
};

class spell_monk_spear_hand_strike : public SpellScriptLoader
{
public:
    spell_monk_spear_hand_strike() : SpellScriptLoader("spell_monk_spear_hand_strike") { }

    class spell_monk_spear_hand_strike_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_spear_hand_strike_SpellScript);

        void Register() override
        {
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_spear_hand_strike_SpellScript();
    }
};

// 124273 - Heavy Stagger
// 124274 - Moderate Stagger
// 124275 - Light Stagger
class spell_monk_stagger_visual : public SpellScriptLoader
{
public:
    spell_monk_stagger_visual() : SpellScriptLoader("spell_monk_stagger_visual") {}

    class spell_monk_stagger_visual_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_stagger_visual_AuraScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return sSpellMgr->GetSpellInfo(SPELL_MONK_STAGGER) != nullptr;
        }

        void HandleDummy1Apply(AuraEffect const* auraEffect, AuraEffectHandleModes /*mode*/)
        {
            Unit* target = GetTarget();
            if (AuraEffect* stagger = target->GetAuraEffect(SPELL_MONK_STAGGER, EFFECT_0))
            {
                stagger->SetAmount(auraEffect->GetAmount());
                stagger->ResetPeriodic();
            }
        }

        void HandleDummy1Remove(AuraEffect const* /*auraEffect*/, AuraEffectHandleModes /*mode*/)
        {
            GetTarget()->RemoveAura(SPELL_MONK_STAGGER);
        }

        void Register() override
        {
            OnEffectApply += AuraEffectApplyFn(spell_monk_stagger_visual_AuraScript::HandleDummy1Apply, EFFECT_2, SPELL_AURA_MELEE_SLOW, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
            OnEffectRemove += AuraEffectRemoveFn(spell_monk_stagger_visual_AuraScript::HandleDummy1Remove, EFFECT_2, SPELL_AURA_MELEE_SLOW, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_stagger_visual_AuraScript();
    }
};

// 115069 - Stance of the Sturdy Ox
class spell_monk_stance_of_the_sturdy_ox : public SpellScriptLoader
{
public:
    spell_monk_stance_of_the_sturdy_ox() : SpellScriptLoader("spell_monk_stance_of_the_sturdy_ox") {}

    class spell_monk_stance_of_the_sturdy_ox_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_stance_of_the_sturdy_ox_AuraScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return sSpellMgr->GetSpellInfo(SPELL_MONK_STAGGER) != nullptr;
        }

        void CalculateAmount(const AuraEffect* /*aurEff*/, int32& amount, bool & /*canBeRecalculated*/)
        {
            amount = -1;
        }

        void HandleAbsorb(AuraEffect* /*auraEffect*/, DamageInfo& dmgInfo, uint32& absorbAmount)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            if (dmgInfo.GetSpellInfo() == sSpellMgr->GetSpellInfo(SPELL_MONK_STAGGER))
                return;

            int32 staggerPct = 0;
            if (dmgInfo.GetSchoolMask() & ~SPELL_SCHOOL_MASK_NORMAL)
            {
                if (SpellEffectInfo const* magicEff = GetSpellInfo()->GetEffect(EFFECT_4))
                    staggerPct = magicEff->CalcValue(GetCaster());
            }
            else if (SpellEffectInfo const* physEff = GetSpellInfo()->GetEffect(EFFECT_0))
                staggerPct = physEff->CalcValue(GetCaster());

            if (staggerPct <= 0)
                return;

            int32 staggerAmount = CalculatePct(dmgInfo.GetDamage(), staggerPct);

            absorbAmount = staggerAmount;

            int32 duration = sSpellMgr->GetSpellInfo(SPELL_MONK_HEAVY_STAGGER)->GetMaxDuration();
            int32 ticks = duration / 500;

            int64 healthPercent = staggerAmount * 100 / caster->GetMaxHealth();

            uint32 staggerVisualSpellId;
            if (healthPercent > 3.34)
                staggerVisualSpellId = SPELL_MONK_HEAVY_STAGGER;
            else if (healthPercent > 1.67)
                staggerVisualSpellId = SPELL_MONK_MODERATE_STAGGER;
            else
                staggerVisualSpellId = SPELL_MONK_LIGHT_STAGGER;

            int32 staggerPerTick = staggerAmount / ticks;

            if (caster->HasAura(SPELL_MONK_STAGGER))
            {
                int32 currentTotalAmount = 0;

                Aura* damageAura = caster->GetAura(SPELL_MONK_STAGGER);
                Aura* visualAura = nullptr;

                if (caster->HasAura(SPELL_MONK_LIGHT_STAGGER))
                    visualAura = caster->GetAura(SPELL_MONK_LIGHT_STAGGER);
                else if (caster->HasAura(SPELL_MONK_MODERATE_STAGGER))
                    visualAura = caster->GetAura(SPELL_MONK_MODERATE_STAGGER);
                else if (caster->HasAura(SPELL_MONK_HEAVY_STAGGER))
                    visualAura = caster->GetAura(SPELL_MONK_HEAVY_STAGGER);

                if (!damageAura || !visualAura)
                    return;

                currentTotalAmount = visualAura->GetEffect(EFFECT_1)->GetAmount();

                staggerAmount += currentTotalAmount;
                staggerPerTick = staggerAmount / ticks;

                float healthPercent = staggerAmount * 100 / caster->GetMaxHealth();

                uint32 staggerVisualSpellId;

                if (healthPercent > 3.34)
                    staggerVisualSpellId = SPELL_MONK_HEAVY_STAGGER;
                else if (healthPercent > 1.67)
                    staggerVisualSpellId = SPELL_MONK_MODERATE_STAGGER;
                else
                    staggerVisualSpellId = SPELL_MONK_LIGHT_STAGGER;


                if (staggerVisualSpellId == visualAura->GetSpellInfo()->Id)
                {
                    visualAura->GetEffect(EFFECT_0)->ChangeAmount(staggerPerTick);
                    visualAura->GetEffect(EFFECT_1)->ChangeAmount(staggerAmount);
                }
                else
                {
                    if (visualAura)
                        caster->RemoveAura(visualAura);

                    caster->CastCustomSpell(caster, staggerVisualSpellId, &staggerPerTick, &staggerAmount, 0, true);
                    // Bob and Weave: only extend newly cast visual, not ChangeAmount-only path.
                    if (Aura* bob = caster->GetAura(SPELL_MONK_BOB_AND_WEAVE))
                    {
                        if (SpellEffectInfo const* dummy30 = bob->GetSpellInfo()->GetEffect(EFFECT_0))
                        {
                            // Dummy 30/10 seconds. 3.0 must not enter Dummy.
                            int32 extra = dummy30->CalcValue(caster) / 10 * IN_MILLISECONDS;
                            if (Aura* visual = caster->GetAura(staggerVisualSpellId))
                            {
                                visual->SetMaxDuration(visual->GetMaxDuration() + extra);
                                visual->SetDuration(visual->GetDuration() + extra);
                            }
                        }
                    }
                }

                if (damageAura)
                    caster->RemoveAura(damageAura);
                caster->CastCustomSpell(SPELL_MONK_STAGGER, SPELLVALUE_BASE_POINT0, staggerPerTick, caster, true);
            }
            else
            {
                caster->CastCustomSpell(SPELL_MONK_STAGGER, SPELLVALUE_BASE_POINT0, staggerPerTick, caster, true);
                caster->CastCustomSpell(caster, staggerVisualSpellId, &staggerPerTick, &staggerAmount, 0, true);
                // Bob and Weave: extend freshly cast stagger visual by Dummy 30/10.
                if (Aura* bob = caster->GetAura(SPELL_MONK_BOB_AND_WEAVE))
                {
                    if (SpellEffectInfo const* dummy30 = bob->GetSpellInfo()->GetEffect(EFFECT_0))
                    {
                        // Dummy 30/10 seconds. 3.0 must not enter Dummy.
                        int32 extra = dummy30->CalcValue(caster) / 10 * IN_MILLISECONDS;
                        if (Aura* visual = caster->GetAura(staggerVisualSpellId))
                        {
                            visual->SetMaxDuration(visual->GetMaxDuration() + extra);
                            visual->SetDuration(visual->GetDuration() + extra);
                        }
                    }
                }
            }
        }

        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_stance_of_the_sturdy_ox_AuraScript::CalculateAmount, EFFECT_2, SPELL_AURA_SCHOOL_ABSORB);
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_stance_of_the_sturdy_ox_AuraScript::CalculateAmount, EFFECT_3, SPELL_AURA_SCHOOL_ABSORB);
            OnEffectAbsorb += AuraEffectAbsorbFn(spell_monk_stance_of_the_sturdy_ox_AuraScript::HandleAbsorb, EFFECT_2);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_stance_of_the_sturdy_ox_AuraScript();
    }
};

//124255
class spell_monk_stagger_damage : public SpellScriptLoader
{
public:
    spell_monk_stagger_damage() : SpellScriptLoader("spell_monk_stagger_damage") { }

    class spell_monk_stagger_damage_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_stagger_damage_AuraScript);

        void HandlePeriodic(AuraEffect const* /*aurEff*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            if (uint32 until = caster->Variables.GetValue<uint32>("MONK_STAGGER_PAUSE_UNTIL", 0))
            {
                if (GameTime::GetGameTimeMS() < until)
                {
                    PreventDefaultAction();
                    return;
                }
            }

            if (!caster->HasAura(SPELL_MONK_LIGHT_STAGGER))
                if (!caster->HasAura(SPELL_MONK_MODERATE_STAGGER))
                    if (!caster->HasAura(SPELL_MONK_HEAVY_STAGGER))
                    {
                        PreventDefaultAction();
                        caster->RemoveAura(SPELL_MONK_STAGGER);
                    }

            Aura* visualAura = nullptr;
            if (caster->HasAura(SPELL_MONK_LIGHT_STAGGER))
                visualAura = caster->GetAura(SPELL_MONK_LIGHT_STAGGER);
            else if (caster->HasAura(SPELL_MONK_MODERATE_STAGGER))
                visualAura = caster->GetAura(SPELL_MONK_MODERATE_STAGGER);
            else if (caster->HasAura(SPELL_MONK_HEAVY_STAGGER))
                visualAura = caster->GetAura(SPELL_MONK_HEAVY_STAGGER);

            if (!visualAura || !visualAura->GetEffect(EFFECT_1)->GetAmount() || !visualAura->GetEffect(EFFECT_0)->GetAmount())
                return;

            int32 newAmount = (visualAura->GetEffect(EFFECT_1)->GetAmount() - visualAura->GetEffect(EFFECT_0)->GetAmount());
            if (newAmount <= 0)
            {
                caster->RemoveAura(SPELL_MONK_LIGHT_STAGGER);
                caster->RemoveAura(SPELL_MONK_MODERATE_STAGGER);
                caster->RemoveAura(SPELL_MONK_HEAVY_STAGGER);
                caster->RemoveAura(SPELL_MONK_STAGGER);
            }
            else
            {
                visualAura->GetEffect(EFFECT_1)->ChangeAmount(newAmount);
            }
        }

        void Register() override
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_stagger_damage_AuraScript::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_stagger_damage_AuraScript();
    }
};

enum TigerLust
{
    SPELL_MONK_TIGER_LUST = 116841,
};

// 116841 - tiger's lust
class spell_monk_tiger_lust : public SpellScriptLoader
{
public:
    spell_monk_tiger_lust() : SpellScriptLoader("spell_monk_tiger_lust") {}

    class spell_monk_tiger_lust_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_tiger_lust_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return sSpellMgr->GetSpellInfo(SPELL_MONK_TIGER_LUST) != nullptr;
        }

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            if (Unit* target = GetHitUnit())
                target->RemoveMovementImpairingAuras();
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_tiger_lust_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_tiger_lust_SpellScript();
    }
};

// 122470 - Touch of Karma
class spell_monk_touch_of_karma : public SpellScriptLoader
{
public:
    spell_monk_touch_of_karma() : SpellScriptLoader("spell_monk_touch_of_karma") { }

    class spell_monk_touch_of_karma_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_touch_of_karma_AuraScript);

        void CalculateAmount(const AuraEffect* aurEff, int32& amount, bool & /*canBeRecalculated*/)
        {
            if (Unit* caster = GetCaster())
                if (SpellEffectInfo const* effInfo = GetAura()->GetSpellEffectInfo(EFFECT_2))
                {
                    amount = int32(caster->CountPctFromMaxHealth(effInfo->CalcValue()));
                    const_cast<AuraEffect*>(aurEff)->SetDamage(amount);
                }
        }

        void OnAbsorb(AuraEffect* aurEff, DamageInfo& /*dmgInfo*/, uint32& absorbAmount)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            SpellEffectInfo const* bounceEff = GetSpellInfo()->GetEffect(EFFECT_3);
            if (!bounceEff)
                return;

            // Bounce is a fraction of this absorb, not of raw GetDamage().
            int32 bounce = CalculatePct(int32(absorbAmount), bounceEff->CalcValue(caster));

            for (AuraApplication* aurApp : caster->GetTargetAuraApplications(SPELL_MONK_TOUCH_OF_KARMA))
                if (aurApp->GetTarget() != caster)
                {
                    int32 periodicDamage = bounce;
                    if (SpellInfo const* karmaDmg = sSpellMgr->GetSpellInfo(SPELL_MONK_TOUCH_OF_KARMA_DAMAGE))
                    {
                        uint32 ticks = karmaDmg->GetMaxTicks(DIFFICULTY_NONE);
                        if (ticks)
                            periodicDamage = bounce / int32(ticks);
                    }
                    periodicDamage += int32(aurApp->GetTarget()->GetRemainingPeriodicAmount(GetCasterGUID(), SPELL_MONK_TOUCH_OF_KARMA_DAMAGE, SPELL_AURA_PERIODIC_DAMAGE));
                    caster->CastCustomSpell(SPELL_MONK_TOUCH_OF_KARMA_DAMAGE, SPELLVALUE_BASE_POINT0, periodicDamage, aurApp->GetTarget(), true, NULL, aurEff);
                }

            if (AuraEffect const* goodKarma = caster->GetAuraEffect(SPELL_MONK_GOOD_KARMA, EFFECT_0))
            {
                int32 healAmt = CalculatePct(bounce, goodKarma->GetAmount());
                if (healAmt > 0)
                {
                    HealInfo healInfo(caster, caster, uint32(healAmt), GetSpellInfo(), GetSpellInfo()->GetSchoolMask());
                    caster->HealBySpell(healInfo);
                }
            }
        }

        void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            GetCaster()->CastSpell(GetCaster(), SPELL_MONK_TOUCH_OF_KARMA_BUFF, true);
        }

        void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            caster->RemoveAura(SPELL_MONK_TOUCH_OF_KARMA_BUFF);
            for (AuraApplication* aurApp : caster->GetTargetAuraApplications(SPELL_MONK_TOUCH_OF_KARMA))
                if (Aura* targetAura = aurApp->GetBase())
                    targetAura->Remove();
        }

        void Register() override
        {
            OnEffectApply += AuraEffectApplyFn(spell_monk_touch_of_karma_AuraScript::HandleApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_touch_of_karma_AuraScript::CalculateAmount, EFFECT_1, SPELL_AURA_SCHOOL_ABSORB);
            OnEffectAbsorb += AuraEffectAbsorbFn(spell_monk_touch_of_karma_AuraScript::OnAbsorb, EFFECT_1);
            OnEffectRemove += AuraEffectRemoveFn(spell_monk_touch_of_karma_AuraScript::HandleRemove, EFFECT_1, SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL);
            OnEffectRemove += AuraEffectRemoveFn(spell_monk_touch_of_karma_AuraScript::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_touch_of_karma_AuraScript();
    }
};

// 125174 - Touch of Karma Buff
class spell_monk_touch_of_karma_buff : public AuraScript
{
    PrepareAuraScript(spell_monk_touch_of_karma_buff);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_TOUCH_OF_KARMA
            });
    }

    void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        for (AuraApplication* aurApp : caster->GetTargetAuraApplications(SPELL_MONK_TOUCH_OF_KARMA))
            if (Aura* targetAura = aurApp->GetBase())
                targetAura->Remove();
    }

    void Register() override
    {
        OnEffectRemove += AuraEffectRemoveFn(spell_monk_touch_of_karma_buff::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

// 101643
class spell_monk_transcendence : public SpellScript
{
public:
    PrepareSpellScript(spell_monk_transcendence);

    void HandleSummon(Creature* creature)
    {
        DespawnSpirit(GetCaster());
        GetCaster()->CastSpell(creature, SPELL_MONK_TRANSCENDENCE_CLONE_TARGET, true);
        creature->CastSpell(creature, SPELL_MONK_TRANSCENDENCE_VISUAL, true);
        creature->SetAIAnimKitId(2223); // Sniff Data
        creature->SetDisableGravity(true);
        creature->SetControlled(true, UNIT_STATE_ROOT);
        GetCaster()->Variables.Set(MONK_TRANSCENDENCE_GUID, creature->GetGUID());
    }

    static Creature* GetSpirit(Unit* caster)
    {
        ObjectGuid spiritGuid = caster->Variables.GetValue<ObjectGuid>(MONK_TRANSCENDENCE_GUID, ObjectGuid());

        if (spiritGuid.IsEmpty())
            return nullptr;

        return ObjectAccessor::GetCreature(*caster, spiritGuid);
    }

    static void DespawnSpirit(Unit* caster)
    {
        // Remove previous one if any
        if (Creature* spirit = GetSpirit(caster))
            spirit->DespawnOrUnsummon();

        caster->Variables.Remove(MONK_TRANSCENDENCE_GUID);
    }

    void Register() override
    {
        OnEffectSummon += SpellOnEffectSummonFn(spell_monk_transcendence::HandleSummon);
    }
};

// 210802 - Spirit of the Crane (Passive)
class spell_monk_spirit_of_the_crane_passive : public AuraScript
{
    PrepareAuraScript(spell_monk_spirit_of_the_crane_passive);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_SPIRIT_OF_THE_CRANE_MANA,
                SPELL_MONK_BLACKOUT_KICK_TRIGGERED
            });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (eventInfo.GetSpellInfo()->Id != SPELL_MONK_BLACKOUT_KICK_TRIGGERED)
            return false;
        return true;
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& /*eventInfo*/)
    {
        // TODO: Basepoints can be float now... this is 1 but needs to be lower.
        GetTarget()->CastSpell(GetTarget(), SPELL_MONK_SPIRIT_OF_THE_CRANE_MANA, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_spirit_of_the_crane_passive::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_monk_spirit_of_the_crane_passive::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// 101643
class aura_monk_transcendence : public AuraScript
{
    PrepareAuraScript(aura_monk_transcendence);

    void OnRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        spell_monk_transcendence::DespawnSpirit(GetTarget());
    }

    void Register() override
    {
        OnEffectRemove += AuraEffectRemoveFn(aura_monk_transcendence::OnRemove, EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

// 119996 - Transcendence: Transfer
class spell_monk_transcendence_transfer : public SpellScript
{
    PrepareSpellScript(spell_monk_transcendence_transfer);

    SpellCastResult CheckCast()
    {
        Unit* caster = GetCaster();

        if (!caster)
            return SPELL_FAILED_ERROR;

        Unit* spirit = spell_monk_transcendence::GetSpirit(caster);
        if (!spirit)
        {
            SetCustomCastResultMessage(SPELL_CUSTOM_ERROR_YOU_HAVE_NO_SPIRIT_ACTIVE);
            return SPELL_FAILED_CUSTOM_ERROR;
        }

        if (!spirit->IsWithinDist(caster, GetSpellInfo()->GetMaxRange(true, caster, GetSpell())))
            return SPELL_FAILED_OUT_OF_RANGE;

        return SPELL_CAST_OK;
    }

    void HandleOnCast()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        Unit* spirit = spell_monk_transcendence::GetSpirit(caster);
        if (!spirit)
            return;

        caster->NearTeleportTo(*spirit, true);
        spirit->NearTeleportTo(*caster, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_monk_transcendence_transfer::CheckCast);
        OnCast += SpellCastFn(spell_monk_transcendence_transfer::HandleOnCast);
    }
};

// 100780
class spell_monk_jab : public SpellScriptLoader
{
public:
    spell_monk_jab() : SpellScriptLoader("spell_monk_jab") { }

    class spell_monk_jab_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_jab_SpellScript);

    public:
        spell_monk_jab_SpellScript() : SpellScript() { }

        void HandleProc()
        {
            Unit* caster = GetCaster();
            if (AuraEffect* comboBreaker = caster->GetAuraEffect(SPELL_MONK_COMBO_BREAKER, EFFECT_0))
            {
                if (roll_chance_i(comboBreaker->GetAmount()))
                    caster->CastSpell(caster, SPELL_MONK_BLACKOUT_KICK_PROC, true);
            }
        }

        void Register() override
        {
            OnHit += SpellHitFn(spell_monk_jab_SpellScript::HandleProc);
        }

    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_jab_SpellScript();
    }
};

// 115098 - Chi Wave
class spell_monk_chi_wave : public SpellScriptLoader
{
public:
    spell_monk_chi_wave() : SpellScriptLoader("spell_monk_chi_wave") {}

    class spell_monk_chi_wave_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_chi_wave_SpellScript);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            Unit* target = GetHitUnit();
            if (!target)
                return;

            if (caster->IsFriendlyTo(target))
                caster->CastCustomSpell(132464, SPELLVALUE_BASE_POINT1, GetEffectValue(), target, true);
            else if (caster->IsValidAttackTarget(target))
                caster->CastCustomSpell(132467, SPELLVALUE_BASE_POINT1, GetEffectValue(), target, true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_chi_wave_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_chi_wave_SpellScript();
    }
};

// 132466 - Chi Wave (target selector)
class spell_monk_chi_wave_target_selector : public SpellScriptLoader
{
public:
    spell_monk_chi_wave_target_selector() : SpellScriptLoader("spell_monk_chi_wave_target_selector") {}

    class DamageUnitCheck
    {
    public:
        DamageUnitCheck(Unit const* source, float range) : m_source(source), m_range(range) {}
        bool operator()(WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            if (!unit)
                return true;

            if (m_source->IsValidAttackTarget(unit) && unit->isTargetableForAttack() && m_source->IsWithinDistInMap(unit, m_range))
            {
                m_range = m_source->GetDistance(unit);
                return false;
            }

            return true;
        }
    private:
        Unit const* m_source;
        float m_range;
    };

    class HealUnitCheck
    {
    public:
        HealUnitCheck(Unit const* source) : m_source(source) {}
        bool operator()(WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            if (!unit)
                return true;

            if (m_source->IsFriendlyTo(unit))
                return false;

            return true;
        }
    private:
        Unit const* m_source;
    };

    class spell_monk_chi_wave_target_selector_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_chi_wave_target_selector_SpellScript);

        bool Load() override
        {
            m_shouldHeal = true; // just for initializing
            return true;
        }

        void SelectTarget(std::list<WorldObject*>& targets)
        {
            if (targets.empty())
                return;

            SpellInfo const* spellInfo = GetTriggeringSpell();
            if (spellInfo->Id == 132467) // Triggered by damage, so we need heal selector
            {
                targets.remove_if(HealUnitCheck(GetCaster()));
                targets.sort(Trinity::HealthPctOrderPred(false)); // Reverse order due to target is selected via std::list back
                m_shouldHeal = true;
            }
            else if (spellInfo->Id == 132464) // Triggered by heal, so we need damage selector
            {
                targets.remove_if(DamageUnitCheck(GetCaster(), 25.0f));
                m_shouldHeal = false;
            }

            if (targets.empty())
                return;

            WorldObject* target = targets.back();
            if (!target)
                return;

            targets.clear();
            targets.push_back(target);
        }

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            if (!GetEffectValue()) // Ran out of bounces
                return;

            if (!GetExplTargetUnit() || !GetOriginalCaster())
                return;

            Unit* target = GetHitUnit();
            if (m_shouldHeal)
                GetExplTargetUnit()->CastCustomSpell(132464, SPELLVALUE_BASE_POINT1, GetEffectValue(), target, true, NULL, NULL, GetOriginalCaster()->GetGUID());
            else
                GetExplTargetUnit()->CastCustomSpell(132467, SPELLVALUE_BASE_POINT1, GetEffectValue(), target, true, NULL, NULL, GetOriginalCaster()->GetGUID());
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_chi_wave_target_selector_SpellScript::SelectTarget, EFFECT_1, TARGET_UNIT_DEST_AREA_ENTRY);
            OnEffectHitTarget += SpellEffectFn(spell_monk_chi_wave_target_selector_SpellScript::HandleDummy, EFFECT_1, SPELL_EFFECT_DUMMY);
        }

        bool m_shouldHeal;
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_chi_wave_target_selector_SpellScript();
    }
};

class spell_monk_fists_of_fury_visual_filter : public SpellScriptLoader
{
public:
    spell_monk_fists_of_fury_visual_filter() : SpellScriptLoader("spell_monk_fists_of_fury_visual_filter") { }

    class spell_monk_fists_of_fury_visual_filter_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_fists_of_fury_visual_filter_SpellScript);

        void RemoveInvalidTargets(std::list<WorldObject*>& targets)
        {
            targets.remove_if(Trinity::UnitAuraCheck(true, 123154, GetCaster()->GetGUID()));
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_fists_of_fury_visual_filter_SpellScript::RemoveInvalidTargets, EFFECT_1, TARGET_UNIT_CONE_ENEMY_24);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_fists_of_fury_visual_filter_SpellScript();
    }
};

class spell_monk_fists_of_fury_visual : public SpellScriptLoader
{
public:
    spell_monk_fists_of_fury_visual() : SpellScriptLoader("spell_monk_fists_of_fury_visual") { }

    class spell_monk_fists_of_fury_visual_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_fists_of_fury_visual_AuraScript);

        void OnApply(const AuraEffect* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            SetMaxDuration(1000); //The spell doesn't have a duration on WoWHead and never ends if we don't give it one, so one sec should be good
            SetDuration(1000);    //Same as above
        }

        void Register() override
        {
            OnEffectApply += AuraEffectApplyFn(spell_monk_fists_of_fury_visual_AuraScript::OnApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_fists_of_fury_visual_AuraScript();
    }
};

// 115546 - Provoke
class spell_monk_provoke : public SpellScriptLoader
{
public:
    spell_monk_provoke() : SpellScriptLoader("spell_monk_provoke") { }

    class spell_monk_provoke_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_provoke_SpellScript);

        static uint32 const BlackOxStatusEntry = 61146;

        bool Validate(SpellInfo const* spellInfo) override
        {
            if (!(spellInfo->GetExplicitTargetMask() & TARGET_FLAG_UNIT_MASK)) // ensure GetExplTargetUnit() will return something meaningful during CheckCast
                return false;
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_PROVOKE_SINGLE_TARGET))
                return false;
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_PROVOKE_AOE))
                return false;
            return true;
        }

        SpellCastResult CheckExplicitTarget()
        {
            if (GetExplTargetUnit()->GetEntry() != BlackOxStatusEntry)
            {
                SpellInfo const* singleTarget = sSpellMgr->AssertSpellInfo(SPELL_MONK_PROVOKE_SINGLE_TARGET);
                SpellCastResult singleTargetExplicitResult = singleTarget->CheckExplicitTarget(GetCaster(), GetExplTargetUnit());
                if (singleTargetExplicitResult != SPELL_CAST_OK)
                    return singleTargetExplicitResult;
            }
            else if (GetExplTargetUnit()->GetOwnerGUID() != GetCaster()->GetGUID())
                return SPELL_FAILED_BAD_TARGETS;

            return SPELL_CAST_OK;
        }

        void HandleDummy(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
            if (GetHitUnit()->GetEntry() != BlackOxStatusEntry)
                GetCaster()->CastSpell(GetHitUnit(), SPELL_MONK_PROVOKE_SINGLE_TARGET, true);
            else
                GetCaster()->CastSpell(GetHitUnit(), SPELL_MONK_PROVOKE_AOE, true);
        }

        void Register() override
        {
            OnCheckCast += SpellCheckCastFn(spell_monk_provoke_SpellScript::CheckExplicitTarget);
            OnEffectHitTarget += SpellEffectFn(spell_monk_provoke_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_provoke_SpellScript();
    }
};

// 116694 - Surging Mist
class spell_monk_surging_mist : public SpellScriptLoader
{
public:
    spell_monk_surging_mist() : SpellScriptLoader("spell_monk_surging_mist") { }

    class spell_monk_surging_mist_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_surging_mist_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_SURGING_MIST_HEAL))
                return false;
            return true;
        }

        void SelectTarget(WorldObject*& target)
        {
            Unit* caster = GetCaster();
            auto const& channelObjects = caster->GetChannelObjects();

            if (caster->GetChannelSpellId() == SPELL_MONK_SOOTHING_MIST)
                if (Unit* soothingMistTarget = (channelObjects.size() == 1 ? ObjectAccessor::GetUnit(*target, *channelObjects.begin()) : nullptr))
                    target = soothingMistTarget;
        }

        void HandleDummy(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
            GetCaster()->CastSpell(GetHitUnit(), SPELL_MONK_SURGING_MIST_HEAL, true);
        }

        void Register() override
        {
            OnObjectTargetSelect += SpellObjectTargetSelectFn(spell_monk_surging_mist_SpellScript::SelectTarget, EFFECT_0, TARGET_UNIT_TARGET_ALLY);
            OnEffectHitTarget += SpellEffectFn(spell_monk_surging_mist_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_surging_mist_SpellScript();
    }
};

// 123273 - Surging Mist (Glyphed)
class spell_monk_surging_mist_glyphed : public SpellScriptLoader
{
public:
    spell_monk_surging_mist_glyphed() : SpellScriptLoader("spell_monk_surging_mist_glyphed") { }

    class spell_monk_surging_mist_glyphed_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_surging_mist_glyphed_SpellScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_SURGING_MIST_HEAL))
                return false;
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_SOOTHING_MIST))
                return false;
            return true;
        }

        void SelectTarget(std::list<WorldObject*>& targets)
        {
            Unit* caster = GetCaster();
            if (caster->GetChannelSpellId() == SPELL_MONK_SOOTHING_MIST)
            {
                targets.clear();
                auto const& channelObjects = caster->GetChannelObjects();

                if (Unit* soothingMistTarget = (channelObjects.size() == 1 ? ObjectAccessor::GetUnit(*caster, *channelObjects.begin()) : nullptr))
                    targets.push_back(soothingMistTarget);
            }
            else
            {
                targets.remove_if([caster](WorldObject* target)
                {
                    return target->GetTypeId() != TYPEID_UNIT || !target->ToUnit()->IsInRaidWith(caster);
                });
                targets.sort(Trinity::HealthPctOrderPred());
                if (!targets.empty())
                    targets.resize(1);
            }

            if (targets.empty())
                targets.push_back(caster);
        }

        void HandleDummy(SpellEffIndex effIndex)
        {
            PreventHitDefaultEffect(effIndex);
            GetCaster()->CastSpell(GetHitUnit(), SPELL_MONK_SURGING_MIST_HEAL, true);
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_surging_mist_glyphed_SpellScript::SelectTarget, EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
            OnEffectHitTarget += SpellEffectFn(spell_monk_surging_mist_glyphed_SpellScript::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_surging_mist_glyphed_SpellScript();
    }
};

// Rising Thunder - 210804
class spell_monk_rising_thunder : public SpellScriptLoader
{
public:
    spell_monk_rising_thunder() : SpellScriptLoader("spell_monk_rising_thunder") { }

    class spell_monk_rising_thunder_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_rising_thunder_AuraScript);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            if (!sSpellMgr->GetSpellInfo(SPELL_MONK_RISING_THUNDER))
                return false;
            return true;
        }

        void HandleEffectProc(AuraEffect const* /*aurEff*/, ProcEventInfo& /*eventInfo*/)
        {
            Unit* caster = GetCaster();

            caster->ToPlayer()->GetSpellHistory()->ResetCooldown(SPELL_MONK_THUNDER_FOCUS_TEA, true);
        }

        void Register() override
        {
            OnEffectProc += AuraEffectProcFn(spell_monk_rising_thunder_AuraScript::HandleEffectProc, EFFECT_0, SPELL_AURA_DUMMY);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_rising_thunder_AuraScript();
    }
};

// 116645 - Teachings of the monastery (Passive)
class spell_monk_teachings_of_the_monastery_passive : public AuraScript
{
    PrepareAuraScript(spell_monk_teachings_of_the_monastery_passive);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_TEACHINGS_OF_THE_MONASTERY,
                SPELL_MONK_TIGER_PALM,
                SPELL_MONK_BLACKOUT_KICK,
            });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (eventInfo.GetSpellInfo()->Id != SPELL_MONK_TIGER_PALM &&
            eventInfo.GetSpellInfo()->Id != SPELL_MONK_BLACKOUT_KICK &&
            eventInfo.GetSpellInfo()->Id != SPELL_MONK_BLACKOUT_KICK_TRIGGERED)
            return false;

        return true;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        if (eventInfo.GetSpellInfo()->Id == SPELL_MONK_TIGER_PALM)
            GetTarget()->CastSpell(GetTarget(), SPELL_MONK_TEACHINGS_OF_THE_MONASTERY, true);
        else if (roll_chance_i(aurEff->GetAmount()))
            GetTarget()->GetSpellHistory()->ResetCooldown(SPELL_MONK_RISING_SUN_KICK, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_teachings_of_the_monastery_passive::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_monk_teachings_of_the_monastery_passive::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// 202090 - Teachings of the monastery (Buff)
class spell_monk_teachings_of_the_monastery_buff : public AuraScript
{
    PrepareAuraScript(spell_monk_teachings_of_the_monastery_buff);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_TEACHINGS_OF_THE_MONASTERY_PASSIVE,
                SPELL_MONK_BLACKOUT_KICK_TRIGGERED,
                SPELL_MONK_BLACKOUT_KICK
            });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!GetTarget()->HasAura(SPELL_MONK_TEACHINGS_OF_THE_MONASTERY_PASSIVE))
            return false;

        if (eventInfo.GetSpellInfo()->Id != SPELL_MONK_BLACKOUT_KICK)
            return false;

        return true;
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        if (Aura* monasteryBuff = GetAura())
        {
            for (uint8 i = 0; i < monasteryBuff->GetStackAmount(); ++i)
                GetTarget()->CastSpell(eventInfo.GetProcTarget(), SPELL_MONK_BLACKOUT_KICK_TRIGGERED);
            monasteryBuff->Remove();
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_teachings_of_the_monastery_buff::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_monk_teachings_of_the_monastery_buff::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

//Rising Sun Kick - 107428
class spell_monk_rising_sun_kick : public SpellScript
{
    PrepareSpellScript(spell_monk_rising_sun_kick);

    void HandleOnHit(SpellEffIndex /*effIndex*/)
    {
        Player* caster = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!target || !caster)
            return;

        if (caster->HasAura(SPELL_MONK_RISING_THUNDER))
            caster->ToPlayer()->GetSpellHistory()->ResetCooldown(SPELL_MONK_THUNDER_FOCUS_TEA, true);

        if (caster->GetSpecializationId() == TALENT_SPEC_MONK_BATTLEDANCER)
            caster->CastSpell(target, SPELL_MONK_MORTAL_WOUNDS, true);

        if (caster->GetSpecializationId() == TALENT_SPEC_MONK_MISTWEAVER && caster->HasAura(SPELL_RISING_MIST))
        {
            caster->CastSpell(nullptr, SPELL_RISING_MIST_HEAL, true);

            int32 addMs = 4 * IN_MILLISECONDS;
            int32 dummy100 = 100;
            if (Aura const* rising = caster->GetAura(SPELL_RISING_MIST))
            {
                if (AuraEffect const* aura42 = rising->GetEffect(EFFECT_0))
                    addMs = aura42->GetAmount() * IN_MILLISECONDS;
                if (SpellEffectInfo const* dummy = rising->GetSpellInfo()->GetEffect(EFFECT_1))
                    dummy100 = dummy->CalcValue(caster);
            }

            auto ExtendHoT = [addMs, dummy100](Aura* aura)
            {
                if (!aura)
                    return;
                int32 cap = int32(int64(aura->GetSpellInfo()->GetMaxDuration()) * (100 + dummy100) / 100);
                aura->SetDuration(std::min(aura->GetDuration() + addMs, cap));
            };

            // Rising Mist only extends HoTs on the current Rising Sun Kick target.
            ExtendHoT(target->GetAura(SPELL_MONK_RENEWING_MIST_HOT, caster->GetGUID()));
            ExtendHoT(target->GetAura(SPELL_MONK_ENVELOPING_MIST, caster->GetGUID()));
            ExtendHoT(target->GetAura(SPELL_MONK_ESSENCE_FONT_PERIODIC_HEAL, caster->GetGUID()));
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_monk_rising_sun_kick::HandleOnHit, EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

//191840 - Essence Font (Heal)
class spell_monk_essence_font_heal : public SpellScriptLoader
{
public:
    spell_monk_essence_font_heal() : SpellScriptLoader("spell_monk_essence_font_heal") { }

    class spell_monk_essence_font_heal_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_essence_font_heal_SpellScript);

        void FilterTargets(std::list<WorldObject*>& p_Targets)
        {
            if (Unit* caster = GetCaster())
            {
                p_Targets.remove_if([caster](WorldObject* object) -> bool
                {
                    if(object == nullptr || object->ToUnit() == nullptr)
                        return true;

                    Unit* unit = object->ToUnit();

                    if (unit == caster)
                        return true;
                    //If the target has the aura and the aura has more than 5 second duration (meaning it was cast less than 1 second ago) we dont keep it
                    if(unit->HasAura(SPELL_MONK_ESSENCE_FONT_HEAL) && unit->GetAura(SPELL_MONK_ESSENCE_FONT_HEAL)->GetDuration() > 5 * IN_MILLISECONDS)
                        return true;

                    return false;
                });

                if (p_Targets.size() > 1)
                {
                    p_Targets.sort(Trinity::HealthPctOrderPred());
                    p_Targets.resize(1);
                }
            }
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_essence_font_heal_SpellScript::FilterTargets, EFFECT_0, TARGET_UNIT_DEST_AREA_ALLY);
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_essence_font_heal_SpellScript::FilterTargets, EFFECT_1, TARGET_UNIT_DEST_AREA_ALLY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_essence_font_heal_SpellScript();
    }
};

//115313 - Summon Jade Serpent Statue
class spell_monk_jade_serpent_statue : public SpellScriptLoader
{
public:
    spell_monk_jade_serpent_statue() : SpellScriptLoader("spell_monk_jade_serpent_statue") { }

    class spell_monk_jade_serpent_statue_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_jade_serpent_statue_SpellScript);

        void HandleSummon()
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            Player* player = caster->ToPlayer();
            if (!player)
                return;

            std::list<Creature*> serpentStatueList;
            player->GetCreatureListWithEntryInGrid(serpentStatueList, MONK_NPC_JADE_SERPENT_STATUE, 500.0f);

            for (std::list<Creature*>::iterator i = serpentStatueList.begin(); i != serpentStatueList.end(); ++i)
            {
                Unit* owner = (*i)->GetOwner();

                if (owner && owner == player && (*i)->IsSummon())
                    continue;

                i = serpentStatueList.erase(i);
            }

            if ((int32)serpentStatueList.size() >= 1)
                serpentStatueList.back()->ToTempSummon()->UnSummon();
        }

        void Register() override
        {
            OnCast += SpellCastFn(spell_monk_jade_serpent_statue_SpellScript::HandleSummon);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_jade_serpent_statue_SpellScript();
    }
};

// 115151 - Renewing Mist
class spell_monk_renewing_mist : public SpellScript
{
    PrepareSpellScript(spell_monk_renewing_mist);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_RENEWING_MIST_HOT
            });
    }

    void HandleDummy(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        if (Unit* target = GetExplTargetUnit())
            GetCaster()->CastSpell(target, SPELL_MONK_RENEWING_MIST_HOT, true);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_monk_renewing_mist::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// 119611 - Renewing Mist (HoT)
class spell_monk_renewing_mist_hot : public AuraScript
{
    PrepareAuraScript(spell_monk_renewing_mist_hot);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_RENEWING_MIST_JUMP,
                SPELL_MONK_RENEWING_MIST
            });
    }

    void HandlePeriodicHeal(AuraEffect const* /*aurEff*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        if (GetTarget()->IsFullHealth())
            caster->CastSpell(GetTarget(), SPELL_MONK_RENEWING_MIST_JUMP, true);
    }

    void CalcAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& /*canBeRecalculated*/)
    {
        Unit* caster = GetCaster();
        if (Aura* counteractAura = caster->GetAura(SPELL_MONK_COUNTERACT_MAGIC))
        {
            Unit::AuraApplicationMap& appliedAuras = GetUnitOwner()->GetAppliedAuras();
            for (Unit::AuraApplicationMap::iterator iter = appliedAuras.begin(); iter != appliedAuras.end(); ++iter)
            {
                Aura* baseAura = iter->second->GetBase();

                if (baseAura->GetSpellInfo()->IsPositive())
                    continue;

                if (!(baseAura->GetSpellInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC))
                    continue;

                if (!(baseAura->GetSpellInfo()->GetDispelMask() & 1 << DISPEL_MAGIC))
                    continue;

                if (baseAura->HasEffectType(SPELL_AURA_PERIODIC_DAMAGE) ||
                    baseAura->HasEffectType(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
                {
                    if (AuraEffect const* effInfo = counteractAura->GetEffect(EFFECT_0))
                    {
                        // TODO: Idk why this all is not increasing the amount
                        AddPct(amount, effInfo->GetAmount());
                    }
                }
            }
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_renewing_mist_hot::HandlePeriodicHeal, EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
        //DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_renewing_mist_hot::CalcAmount, EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
    }
};

// 119607 - Renewing Mist Jump
class spell_monk_renewing_mist_jump : public SpellScript
{
    PrepareSpellScript(spell_monk_renewing_mist_jump);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_RENEWING_MIST_HOT
            });
    }

    void HandleTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        Unit* previousTarget = GetExplTargetUnit();

        // Not remove full health targets now, dancing mists talent can jump on full health too
        targets.remove_if([caster, previousTarget](WorldObject* a)
        {
            Unit* ally = a->ToUnit();
            if (!ally || ally->HasAura(SPELL_MONK_RENEWING_MIST_HOT, caster->GetGUID()) || ally == previousTarget)
                return true;

            return false;
        });

        targets.remove_if([](WorldObject* a)
        {
            Unit* ally = a->ToUnit();
            if (!ally || ally->IsFullHealth())
                return true;

            return false;
        });

        if (targets.size() > 1)
        {
            targets.sort(Trinity::HealthPctOrderPred());
            targets.resize(1);
        }

        _previousTargetGuid = previousTarget->GetGUID();
    }

    void HandleHit(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* caster = GetCaster();
        Unit* previousTarget = ObjectAccessor::GetUnit(*caster, _previousTargetGuid);

        if (previousTarget)
        {
            if (Aura* oldAura = previousTarget->GetAura(SPELL_MONK_RENEWING_MIST_HOT, GetCaster()->GetGUID()))
            {
                if (Aura* newAura = caster->AddAura(SPELL_MONK_RENEWING_MIST_HOT, GetHitUnit()))
                {
                    newAura->SetDuration(oldAura->GetDuration());
                    previousTarget->SendPlaySpellVisual(GetHitUnit()->GetGUID(), SPELL_MONK_VISUAL_RENEWING_MIST, 0, 0, 50.f);
                    oldAura->Remove();
                }
            }
        }
    }

private:
    ObjectGuid _previousTargetGuid;
    ObjectGuid _additionalTargetGuid;

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_renewing_mist_jump::HandleTargets, EFFECT_1, TARGET_UNIT_DEST_AREA_ALLY);
        OnEffectHitTarget += SpellEffectFn(spell_monk_renewing_mist_jump::HandleHit, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

//193884 Soothing Mist
class spell_monk_soothing_mist_aura : public SpellScriptLoader
{
public:
    spell_monk_soothing_mist_aura() : SpellScriptLoader("spell_monk_soothing_mist_aura") { }

    class spell_monk_soothing_mist_aura_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_soothing_mist_aura_AuraScript);

        void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
        {
            if (Unit* caster = GetCaster())
                if(eventInfo.GetProcTarget())
                    caster->CastSpell(eventInfo.GetActionTarget(), SPELL_MONK_SOOTHING_MIST, true);
        }

        void Register() override
        {
            OnEffectProc += AuraEffectProcFn(spell_monk_soothing_mist_aura_AuraScript::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_soothing_mist_aura_AuraScript();
    }
};

class spell_monk_fists_of_fury : public SpellScriptLoader
{
public:
    spell_monk_fists_of_fury() : SpellScriptLoader("spell_monk_fists_of_fury") { }

    class spell_monk_fists_of_fury_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_fists_of_fury_AuraScript);

        void HandlePeriodicStun(AuraEffect const* /*aurEff*/)
        {
            PreventDefaultAction();
        }

        void HandlePeriodic(AuraEffect const* /*aurEff*/)
        {
            PreventDefaultAction();
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            if (!caster || !target)
                return;

            caster->CastSpell(target, SPELL_MONK_FISTS_OF_FURY_DAMAGE, true);
            caster->CastSpell(target, SPELL_MONK_FISTS_OF_FURY_STUN, true);
        }

        void Register() override
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_fists_of_fury_AuraScript::HandlePeriodicStun, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_fists_of_fury_AuraScript::HandlePeriodic, EFFECT_2, SPELL_AURA_PERIODIC_DUMMY);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_fists_of_fury_AuraScript();
    }
};

class spell_monk_fists_of_fury_damage : public SpellScriptLoader
{
public:
    spell_monk_fists_of_fury_damage() : SpellScriptLoader("spell_monk_fists_of_fury_damage") { }

    class spell_monk_fists_of_fury_damage_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_fists_of_fury_damage_SpellScript);

        void HandleDamage(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            Unit* target = GetHitUnit();
            if (!caster || !target)
                return;

            SpellInfo const* fof = sSpellMgr->GetSpellInfo(SPELL_MONK_FISTS_OF_FURY);
            if (!fof || !fof->GetEffect(EFFECT_4))
                return;

            int32 dmg = fof->GetEffect(EFFECT_4)->CalcValue(caster);
            dmg = caster->SpellDamageBonusDone(target, GetSpellInfo(), dmg, SPELL_DIRECT_DAMAGE, GetSpellInfo()->GetEffect(EFFECT_0));
            dmg = target->SpellDamageBonusTaken(caster, GetSpellInfo(), dmg, SPELL_DIRECT_DAMAGE, GetSpellInfo()->GetEffect(EFFECT_0));

            if (GetHitUnit() != GetExplTargetUnit() && fof->GetEffect(EFFECT_5))
            {
                int32 extraPct = fof->GetEffect(EFFECT_5)->CalcValue(caster);
                dmg = CalculatePct(dmg, extraPct);
            }

            SetHitDamage(dmg);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_fists_of_fury_damage_SpellScript::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_fists_of_fury_damage_SpellScript();
    }
};

class spell_monk_life_cocoon : public SpellScriptLoader
{
public:
    spell_monk_life_cocoon() : SpellScriptLoader("spell_monk_life_cocoon") { }

    class spell_monk_life_cocoon_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_life_cocoon_AuraScript);

        void CalcAbsorb(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            SpellEffectInfo const* dummy = GetSpellInfo()->GetEffect(EFFECT_2);
            if (!dummy)
                return;

            amount = int32(caster->CountPctFromMaxHealth(dummy->CalcValue(caster)));
            canBeRecalculated = false;
        }

        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_life_cocoon_AuraScript::CalcAbsorb, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_life_cocoon_AuraScript();
    }
};

// Windwalking - 157411
// AreaTriggerID - 2763
struct at_monk_windwalking : AreaTriggerAI
{
    at_monk_windwalking(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    void OnUnitEnter(Unit* unit) override
    {
        Unit* caster = at->GetCaster();

        if (!caster || !unit)
            return;

        if (!caster->ToPlayer())
            return;

        if (Aura* aur = unit->GetAura(SPELL_MONK_WINDWALKER_AURA))
            aur->SetDuration(-1);
        else if (caster->IsFriendlyTo(unit))
            caster->CastSpell(unit, SPELL_MONK_WINDWALKER_AURA, true);
    }

    void OnUnitExit(Unit* unit) override
    {
        Unit* caster = at->GetCaster();

        if (!caster || !unit)
            return;

        if (!caster->ToPlayer())
            return;

        if (unit->HasAura(SPELL_MONK_WINDWALKING) && unit != caster) // Don't remove from other WW monks.
            return;

        if (Aura* aur = unit->GetAura(SPELL_MONK_WINDWALKER_AURA, caster->GetGUID()))
        {
            aur->SetMaxDuration(10 * IN_MILLISECONDS);
            aur->SetDuration(10 * IN_MILLISECONDS);
        }
    }

    void OnRemove() override
    {
        Unit* caster = at->GetCaster();

        if (!caster)
            return;

        if (!caster->ToPlayer())
            return;

        for (auto guid : at->GetInsideUnits())
        {
            if (Unit* unit = ObjectAccessor::GetUnit(*caster, guid))
            {
                if (unit->HasAura(SPELL_MONK_WINDWALKING) && unit != caster) // Don't remove from other WW monks.
                    continue;

                if (Aura* aur = unit->GetAura(SPELL_MONK_WINDWALKER_AURA, caster->GetGUID()))
                {
                    aur->SetMaxDuration(10 * IN_MILLISECONDS);
                    aur->SetDuration(10 * IN_MILLISECONDS);
                }
            }
        }
    }
};

// Spell 124503
// AT ID : 3282
struct at_monk_gift_of_the_ox_sphere : AreaTriggerAI
{
    uint32 pickupDelay;

    at_monk_gift_of_the_ox_sphere(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger)
    {
        pickupDelay = 1000;
    }

    enum SpellsUsed
    {
        SPELL_MONK_GIFT_OF_THE_OX_HEAL      = 178173,
        SPELL_MONK_HEALING_SPHERE_COOLDOWN  = 224863
    };

    void OnUpdate(uint32 diff)  override
    {
        if (pickupDelay >= diff)
            pickupDelay -= diff;
        else
            pickupDelay = 0;
    }

    void OnUnitEnter(Unit* unit) override
    {
        if (Unit* caster = at->GetCaster())
        {
            if (unit == caster && !pickupDelay)
            {
                caster->CastSpell(caster, SPELL_MONK_GIFT_OF_THE_OX_HEAL, true);
                at->Remove();
            }
        }
    }

    void OnRemove() override
    {
        //Todo : Remove cooldown
        if (Unit* caster = at->GetCaster())
            if(caster->HasAura(SPELL_MONK_HEALING_SPHERE_COOLDOWN))
                caster->RemoveAura(SPELL_MONK_HEALING_SPHERE_COOLDOWN);
    }
};

//124502 - Gift of the Ox
class spell_monk_gift_of_the_ox_aura : public PlayerScript
{
public:
    spell_monk_gift_of_the_ox_aura() : PlayerScript("spell_monk_gift_of_the_ox_aura") {}

    enum UsedSpells
    {
        SPELL_MONK_HEALING_SPHERE_COOLDOWN  = 224863
    };

    std::vector<uint32> spellsToCast
    {
        SPELL_MONK_GIFT_OF_THE_OX_AT_RIGHT,
        SPELL_MONK_GIFT_OF_THE_OX_AT_LEFT,
    };

    void OnTakeDamage(Player* victim, uint32 damage, SpellSchoolMask /*school*/) override
    {
        if (!damage || !victim)
            return;

        if(!victim->HasAura(SPELL_MONK_GIFT_OF_THE_OX_AURA))
            return;

        uint32 spellToCast = spellsToCast[urand(0, (spellsToCast.size() - 1))];

        Aura const* gift = victim->GetAura(SPELL_MONK_GIFT_OF_THE_OX_AURA);
        if (!gift)
            return;
        SpellEffectInfo const* dummy = gift->GetSpellInfo()->GetEffect(EFFECT_0);
        if (!dummy)
            return;

        if (roll_chance_i(dummy->CalcValue(victim)))
        {
            if (!victim->HasAura(SPELL_MONK_HEALING_SPHERE_COOLDOWN))
            {
                victim->CastSpell(victim, SPELL_MONK_HEALING_SPHERE_COOLDOWN, true);
                victim->CastSpell(victim, spellToCast, true);
            }
        }
    }

};

// 117906 - Mastery : Elusive Brawler
class spell_monk_elusive_brawler_mastery : public AuraScript
{
    PrepareAuraScript(spell_monk_elusive_brawler_mastery);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (eventInfo.GetTypeMask() & TAKEN_HIT_PROC_FLAG_MASK)
            return true;

        return eventInfo.GetProcSpell() &&
               eventInfo.GetProcSpell()->GetSpellInfo()->Id == SPELL_MONK_BLACKOUT_STRIKE;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_elusive_brawler_mastery::CheckProc);
    }
};

// 195630 - Elusive Brawler
class spell_monk_elusive_brawler_stacks : public AuraScript
{
    PrepareAuraScript(spell_monk_elusive_brawler_stacks);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!(eventInfo.GetHitMask() & PROC_HIT_DODGE))
            return false;

        if (Aura* elusiveBrawler = GetCaster()->GetAura(SPELL_MONK_ELUSIVE_BRAWLER, GetCaster()->GetGUID()))
            elusiveBrawler->SetDuration(0);

        return true;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_elusive_brawler_stacks::CheckProc);
    }
};

// Dampen Harm - 122278
class spell_monk_dampen_harm : public SpellScriptLoader
{
public:
    spell_monk_dampen_harm() : SpellScriptLoader("spell_monk_dampen_harm") { }
    class spell_monk_dampen_harm_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_dampen_harm_AuraScript);
        int32 healthPct;

        bool Load() override
        {
            healthPct = GetSpellInfo()->GetEffect(EFFECT_0)->CalcValue(GetCaster());
            return GetUnitOwner()->ToPlayer();
        }

        void CalculateAmount(AuraEffect const* /*auraEffect*/, int32& amount, bool& /*canBeRecalculated*/)
        {
            amount = -1;
        }

        void Absorb(AuraEffect* auraEffect, DamageInfo& dmgInfo, uint32& absorbAmount)
        {
            Unit* target = GetTarget();
            uint32 health = target->CountPctFromMaxHealth(healthPct);
            if (dmgInfo.GetDamage() < health)
                return;

            absorbAmount = dmgInfo.GetDamage() * (GetSpellInfo()->GetEffect(EFFECT_0)->CalcValue(GetCaster()) / 100);
            auraEffect->GetBase()->DropCharge();
        }
        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_dampen_harm_AuraScript::CalculateAmount, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
            OnEffectAbsorb += AuraEffectAbsorbFn(spell_monk_dampen_harm_AuraScript::Absorb, EFFECT_0);
        }
    };
    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_dampen_harm_AuraScript();
    }
};

// Chi Burst damage - 123986
// AreaTriggerID - 5302
struct at_monk_chi_burst_damage : AreaTriggerAI
{
    at_monk_chi_burst_damage(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    void OnUnitEnter(Unit* unit) override
    {
        if (Unit* caster = at->GetCaster())
            if (caster->IsValidAttackTarget(unit))
                caster->CastSpell(unit, SPELL_MONK_CHI_BURST_DAMAGE, true);
    }
};

// Chi Burst heal - 123986
// AreaTriggerID - 5300
struct at_monk_chi_burst_heal : AreaTriggerAI
{
    at_monk_chi_burst_heal(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    void OnUnitEnter(Unit* unit) override
    {
        if (Unit* caster = at->GetCaster())
            if (caster->IsValidAssistTarget(unit))
                caster->CastSpell(unit, SPELL_MONK_CHI_BURST_HEAL, true);
    }
};

// Chi Burst heal - 130654
class spell_monk_chi_burst_heal : public SpellScriptLoader
{
public:
    spell_monk_chi_burst_heal() : SpellScriptLoader("spell_monk_chi_burst_heal") {}

    class spell_monk_chi_burst_heal_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_chi_burst_heal_SpellScript);

        void Register() override
        {
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_chi_burst_heal_SpellScript();
    }
};

//197915
class spell_monk_lifecycles : public SpellScriptLoader
{
public:
    spell_monk_lifecycles() : SpellScriptLoader("spell_monk_lifecycles") { }

    class spell_monk_lifecycles_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_lifecycles_AuraScript);

        void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& procInfo)
        {
            Unit* caster = GetCaster();

            if (!caster || !procInfo.GetSpellInfo())
                return;

            if (procInfo.GetSpellInfo()->Id == SPELL_MONK_VIVIFY)
                caster->CastSpell(caster, SPELL_MONK_LIFECYCLES_ENVELOPING_MIST, true);

            if (procInfo.GetSpellInfo()->Id == SPELL_MONK_ENVELOPING_MIST)
                caster->CastSpell(caster, SPELL_MONK_LIFECYCLES_VIVIFY, true);
        }

        void Register() override
        {
            OnEffectProc += AuraEffectProcFn(spell_monk_lifecycles_AuraScript::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_lifecycles_AuraScript();
    }
};

//5484
struct at_monk_song_of_chiji : AreaTriggerAI
{
    at_monk_song_of_chiji(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    /*void OnSetCreatePosition(Unit* caster, Position& startPos, Position& endPos, std::list<Position>& path) override
    {
        if (!caster)
            return;

        if (!caster->ToPlayer())
            return;

        startPos = caster->GetPosition();
        at->SetLinearMove(caster, startPos, endPos, path, 40.0f);
    }*/

    void OnUnitEnter(Unit* unit) override
    {
        Unit* caster = at->GetCaster();

        if (!caster || !unit)
            return;

        if (!caster->ToPlayer())
            return;

        if(unit != caster && caster->IsValidAttackTarget(unit))
            caster->CastSpell(unit, SPELL_MONK_SONG_OF_CHIJI, true);
    }
};

//137639
class spell_monk_storm_earth_and_fire : public AuraScript
{
    PrepareAuraScript(spell_monk_storm_earth_and_fire);

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        Unit* target = GetTarget();
        target->CastSpell(target, SPELL_MONK_SEF_STORM_VISUAL, true);
        target->CastSpell(target, SPELL_MONK_SEF_SUMMON_EARTH, true);
        target->CastSpell(target, SPELL_MONK_SEF_SUMMON_FIRE,  true);
    }

    void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_MONK_SEF_STORM_VISUAL);

        if (Creature* fireSpirit = GetTarget()->GetSummonedCreatureByEntry(NPC_FIRE_SPIRIT))
            fireSpirit->ToTempSummon()->DespawnOrUnsummon();

        if (Creature* earthSpirit = GetTarget()->GetSummonedCreatureByEntry(NPC_EARTH_SPIRIT))
            earthSpirit->ToTempSummon()->DespawnOrUnsummon();
    }

    void Register() override
    {
        OnEffectApply  +=  AuraEffectApplyFn(spell_monk_storm_earth_and_fire::HandleApply,  EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
        OnEffectRemove += AuraEffectRemoveFn(spell_monk_storm_earth_and_fire::HandleRemove, EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

// 69791 - 69792
struct npc_monk_sef_spirit : public ScriptedAI
{
    npc_monk_sef_spirit(Creature* creature) : ScriptedAI(creature) {}

    void IsSummonedBy(Unit* summoner)
    {
        me->SetLevel(summoner->getLevel());
        summoner->CastSpell(me, SPELL_MONK_TRANSCENDENCE_CLONE_TARGET, true);
        me->CastSpell(me, me->GetEntry() == NPC_FIRE_SPIRIT ? SPELL_MONK_SEF_FIRE_VISUAL : SPELL_MONK_SEF_EARTH_VISUAL, true);
        me->CastSpell(me, SPELL_MONK_SEF_SUMMONS_STATS, true);

        if (Unit* target = ObjectAccessor::GetUnit(*summoner, summoner->GetTarget()))
            me->CastSpell(target, SPELL_MONK_SEF_CHARGE, true);
    }
};

// 63508
struct npc_monk_xuen : public ScriptedAI
{
    npc_monk_xuen(Creature* creature) : ScriptedAI(creature) {}

    void IsSummonedBy(Unit* /*summoner*/)
    {
        me->CastSpell(me, SPELL_MONK_XUEN_AURA, true);
    }
};

class playerScript_monk_earth_fire_storm : public PlayerScript
{
public:
    playerScript_monk_earth_fire_storm() : PlayerScript("playerScript_monk_earth_fire_storm") {}

    void OnSuccessfulSpellCast(Player* player, Spell* spell) override
    {
        SpellInfo const* spellInfo = spell->GetSpellInfo();
        if (player->HasAura(SPELL_MONK_SERENITY))
            return;
        if (player->HasAura(SPELL_MONK_SEF) && !spellInfo->IsPositive())
        {
            if (Unit* target = ObjectAccessor::GetUnit(*player, player->GetTarget()))
            {
                if (Creature* fireSpirit = player->GetSummonedCreatureByEntry(NPC_FIRE_SPIRIT))
                    fireSpirit->CastSpell(target, spellInfo->Id, true);

                if (Creature* earthSpirit = player->GetSummonedCreatureByEntry(NPC_EARTH_SPIRIT))
                    earthSpirit->CastSpell(target, spellInfo->Id, true);
            }
        }
    }
};

/*
END OF STORM EARTH AND FIRE
*/

//115399
class spell_monk_black_ox_brew : public SpellScriptLoader
{
public:
    spell_monk_black_ox_brew() : SpellScriptLoader("spell_monk_black_ox_brew") { }

    class spell_monk_black_ox_brew_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_black_ox_brew_SpellScript);

        void HandleHit(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            caster->GetSpellHistory()->ResetCharges(sSpellMgr->GetSpellInfo(SPELL_MONK_PURIFYING_BREW)->ChargeCategoryId);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_monk_black_ox_brew_SpellScript::HandleHit, EFFECT_0, SPELL_EFFECT_ENERGIZE);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_black_ox_brew_SpellScript();
    }
};

//122280
class spell_monk_healing_elixirs_aura : public SpellScriptLoader
{
public:
    spell_monk_healing_elixirs_aura() : SpellScriptLoader("spell_monk_healing_elixirs_aura") { }
    class spell_monk_healing_elixirs_aura_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_healing_elixirs_aura_AuraScript);
        void OnProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
        {
            PreventDefaultAction();
            if (!GetCaster())
                return;
            if (!eventInfo.GetDamageInfo())
                return;
            if (!eventInfo.GetDamageInfo()->GetDamage())
                return;
            if (Unit* caster = GetCaster())
            {
                if (caster->HealthBelowPctDamaged(35, eventInfo.GetDamageInfo()->GetDamage()))
                {
                    caster->CastSpell(caster, SPELL_MONK_HEALING_ELIXIRS_RESTORE_HEALTH, true);
                    caster->GetSpellHistory()->ConsumeCharge(SPELL_MONK_HEALING_ELIXIRS_RESTORE_HEALTH);
                }
            }
        }
        void Register() override
        {
            OnEffectProc += AuraEffectProcFn(spell_monk_healing_elixirs_aura_AuraScript::OnProc, EFFECT_0, SPELL_AURA_DUMMY);
        }
    };
    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_healing_elixirs_aura_AuraScript();
    }
};

//202162 - Guard
class spell_monk_guard : public SpellScriptLoader
{
public:
    spell_monk_guard() : SpellScriptLoader("spell_monk_guard") { }

    class spell_monk_guard_AuraScript : public AuraScript
    {
        PrepareAuraScript(spell_monk_guard_AuraScript);

        void CalcAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& /*canBeRecalculated*/)
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            if (SpellEffectInfo const* absorbEff = GetSpellInfo()->GetEffect(EFFECT_0))
                amount = absorbEff->CalcValue(caster);
        }

        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_monk_guard_AuraScript::CalcAmount, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        }
    };

    AuraScript* GetAuraScript() const override
    {
        return new spell_monk_guard_AuraScript();
    }
};

// Whirling Dragon Punch - 152175
class playerScript_monk_whirling_dragon_punch : public PlayerScript
{
public:
    playerScript_monk_whirling_dragon_punch() : PlayerScript("playerScript_monk_whirling_dragon_punch") {}

    void OnCooldownStart(Player* player, SpellInfo const* spellInfo, uint32 /*itemId*/, int32& cooldown, uint32& /*categoryId*/, int32& /*categoryCooldown*/) override
    {
        SpellInfo const* fistsOfFuryInfo = sSpellMgr->GetSpellInfo(SPELL_MONK_FISTS_OF_FURY);
        SpellInfo const* risingSunKickInfo = sSpellMgr->GetSpellInfo(SPELL_MONK_RISING_SUN_KICK);
        if (!fistsOfFuryInfo || !risingSunKickInfo)
            return;

        if (spellInfo->Id == SPELL_MONK_FISTS_OF_FURY)
            ApplyCasterAura(player, cooldown, int32(player->GetSpellHistory()->GetRemainingCooldown(risingSunKickInfo)));
        else if (spellInfo->Id == SPELL_MONK_RISING_SUN_KICK)
            ApplyCasterAura(player, cooldown, int32(player->GetSpellHistory()->GetRemainingCooldown(fistsOfFuryInfo)));
    }

private:
    void ApplyCasterAura(Player* player, int32 cooldown1, int32 cooldown2)
    {
        if (cooldown1 > 0 && cooldown2 > 0)
        {
            uint32 whirlingDragonPunchAuraDuration = std::min(cooldown1, cooldown2);
            player->CastSpell(player, SPELL_MONK_WHIRLING_DRAGON_PUNCH_CASTER_AURA, true);

            if (Aura* aura = player->GetAura(SPELL_MONK_WHIRLING_DRAGON_PUNCH_CASTER_AURA))
                aura->SetDuration(whirlingDragonPunchAuraDuration);
        }
    }
};

// Whirling Dragon Punch - 152175
class spell_monk_whirling_dragon_punch : public AuraScript
{
    PrepareAuraScript(spell_monk_whirling_dragon_punch);

    void OnTick(AuraEffect const* /*aurEff*/)
    {
        if (GetCaster())
            GetCaster()->CastSpell(GetCaster(), SPELL_MONK_WHIRLING_DRAGON_PUNCH_DAMAGE, true);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_whirling_dragon_punch::OnTick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// 100780
class spell_monk_tiger_palm : public SpellScript
{
    PrepareSpellScript(spell_monk_tiger_palm);

    void HandleHit(SpellEffIndex /*effIndex*/)
    {
        if (Aura* powerStrikes = GetCaster()->GetAura(SPELL_MONK_POWER_STRIKES_AURA))
        {
            SetEffectValue(GetEffectValue() + powerStrikes->GetEffect(EFFECT_0)->GetBaseAmount());
            powerStrikes->Remove();
        }
    }

    void HandleDamage(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(SPELL_MONK_BLACKOUT_COMBO_BUFF))
            return;

        if (SpellInfo const* combo = sSpellMgr->GetSpellInfo(SPELL_MONK_BLACKOUT_COMBO))
            if (SpellEffectInfo const* dummy100 = combo->GetEffect(EFFECT_0))
                SetHitDamage(GetHitDamage() + CalculatePct(GetHitDamage(), dummy100->CalcValue(caster)));

        caster->RemoveAura(SPELL_MONK_BLACKOUT_COMBO_BUFF);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_monk_tiger_palm::HandleHit, EFFECT_1, SPELL_EFFECT_ENERGIZE);
        OnEffectHitTarget += SpellEffectFn(spell_monk_tiger_palm::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// 116670 - Vivify
class spell_monk_vivify : public SpellScriptLoader
{
public:
    spell_monk_vivify() : SpellScriptLoader("spell_monk_vivify") { }

    class spell_monk_vivify_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_monk_vivify_SpellScript);

        void FilterRenewingMist(std::list<WorldObject*>& targets)
        {
            targets.remove_if(Trinity::UnitAuraCheck(false, SPELL_MONK_RENEWING_MIST_HOT, GetCaster()->GetGUID()));
        }

        void HandleOnPrepare()
        {
            if (GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL) && GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL)->GetSpellInfo()->Id == SPELL_MONK_SOOTHING_MIST)
            {
                TriggerCastFlags castFlags = TriggerCastFlags(GetSpell()->GetTriggeredCastFlags() | TRIGGERED_CAST_DIRECTLY);
                GetSpell()->SetTriggerCastFlags(castFlags);
                SpellCastTargets targets = GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL)->m_targets;
                GetSpell()->InitExplicitTargets(targets);
            }
        }

        void Register() override
        {
            OnPrepare += SpellOnPrepareFn(spell_monk_vivify_SpellScript::HandleOnPrepare);
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_monk_vivify_SpellScript::FilterRenewingMist, EFFECT_1, TARGET_UNIT_DEST_AREA_ALLY);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_monk_vivify_SpellScript();
    }
};

// 216113 - Way of the crane (Passive)
class spell_monk_way_of_the_crane : public AuraScript
{
    PrepareAuraScript(spell_monk_way_of_the_crane);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            {
                SPELL_MONK_WAY_OF_THE_CRANE_HEAL
            });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (DamageInfo* dInfo = eventInfo.GetDamageInfo())
            if (dInfo->GetDamage() > 0)
                return true;
        return false;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        int32 damage = eventInfo.GetDamageInfo()->GetDamage();
        AddPct(damage, aurEff->GetAmount());
        eventInfo.GetActor()->CastCustomSpell(SPELL_MONK_WAY_OF_THE_CRANE_HEAL, SPELLVALUE_BASE_POINT0, damage, eventInfo.GetActor(), true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_monk_way_of_the_crane::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_monk_way_of_the_crane::HandleProc, EFFECT_3, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

//60849
struct npc_monk_jade_serpent_statue : public ScriptedAI
{
    npc_monk_jade_serpent_statue(Creature* c) : ScriptedAI(c) { }

    void UpdateAI(uint32 /*diff*/) override
    {
        if (Unit* owner = me->GetOwner())
        {
            if (Player* player = owner->ToPlayer())
            {
                if (player->getClass() != CLASS_MONK)
                    return;
                else
                {
                    if (player->GetSpecializationId() != TALENT_SPEC_MONK_MISTWEAVER && me->IsInWorld())
                        me->DespawnOrUnsummon();
                }
            }
        }
    }
};

//3983
struct at_monk_ring_of_peace : AreaTriggerAI
{
    at_monk_ring_of_peace(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    void OnUnitEnter(Unit* unit) override
    {
        if (Unit* caster = at->GetCaster())
            if (caster->IsValidAttackTarget(unit))
                caster->CastSpell(unit->GetPosition(), SPELL_MONK_RING_OF_PEACE_KNOCKBACK, true);
    }
};

//8647
class mystic_touch : public PlayerScript
{
public:
    mystic_touch() : PlayerScript("mystic_touch") { }

    void OnDamage(Unit* caster, Unit* target, uint32& /*damage*/, SpellInfo const* /*spellProto*/)
    {
        if (Player* player = caster->ToPlayer())
        {
            if (player->getClass() != CLASS_MONK)
                return;
        }

        if (!caster || !target)
            return;

        if (target->HasAura(SPELL_MONK_MYSTIC_TOUCH_TARGET_DEBUFF))
            return;

        if (caster->HasAura(SPELL_MONK_MYSTIC_TOUCH) && !target->HasAura(SPELL_MONK_MYSTIC_TOUCH_TARGET_DEBUFF))
        {
            if (caster->IsWithinMeleeRange(target))
                caster->CastSpell(nullptr, SPELL_MONK_MYSTIC_TOUCH_TARGET_DEBUFF, true);
        }
    }
};

//191837 - Essence Font
class spell_monk_essence_font : public SpellScript
{
    PrepareSpellScript(spell_monk_essence_font);

    void HandleOnCast()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        std::list<Unit*> u_li;
        caster->GetFriendlyUnitListInRange(u_li, 30.0f, false);

        int32 targetLimit = 6;
        if (SpellEffectInfo const* countEff = GetSpellInfo()->GetEffect(EFFECT_0))
            targetLimit = countEff->BasePoints;

        if (!u_li.empty())
            Trinity::Containers::RandomResize(u_li, uint32(targetLimit));

        int32 extraMs = 0;
        if (caster->HasAura(SPELL_MONK_UPWELLING))
        {
            extraMs = caster->Variables.GetValue<int32>("MONK_UPWELLING_EXTRA_MS", 0);
            caster->Variables.Remove("MONK_UPWELLING_EXTRA_MS");
        }

        for (Unit* ally : u_li)
        {
            if (Aura* hot = caster->AddAura(SPELL_MONK_ESSENCE_FONT_PERIODIC_HEAL, ally))
            {
                if (extraMs > 0)
                {
                    hot->SetMaxDuration(hot->GetMaxDuration() + extraMs);
                    hot->SetDuration(hot->GetDuration() + extraMs);
                }
            }
        }
    }

    void Register() override
    {
        OnCast += SpellCastFn(spell_monk_essence_font::HandleOnCast);
    }
};

// 115308 - Ironskin Brew. Dummy 75 is tooltip, do not ChangeAmount.
class spell_monk_ironskin_brew : public SpellScript
{
    PrepareSpellScript(spell_monk_ironskin_brew);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_IRONSKIN_BREW_BUFF });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        SpellInfo const* buffInfo = sSpellMgr->GetSpellInfo(SPELL_MONK_IRONSKIN_BREW_BUFF);
        if (!buffInfo)
            return;

        int32 baseDuration = buffInfo->GetMaxDuration();
        int32 dummy3 = 3;
        if (SpellEffectInfo const* capEff = buffInfo->GetEffect(EFFECT_1))
            dummy3 = capEff->CalcValue(caster);
        int32 cap = dummy3 * baseDuration;

        if (Aura* buff = caster->GetAura(SPELL_MONK_IRONSKIN_BREW_BUFF))
        {
            int32 newDur = std::min(buff->GetDuration() + baseDuration, cap);
            buff->SetMaxDuration(newDur);
            buff->SetDuration(newDur);
        }
        else
            caster->CastSpell(caster, SPELL_MONK_IRONSKIN_BREW_BUFF, true);

        if (caster->HasAura(SPELL_MONK_BLACKOUT_COMBO_BUFF))
        {
            int32 pauseSec = 3;
            if (SpellInfo const* combo = sSpellMgr->GetSpellInfo(SPELL_MONK_BLACKOUT_COMBO))
                if (SpellEffectInfo const* dummy = combo->GetEffect(EFFECT_3))
                    pauseSec = dummy->CalcValue(caster);
            caster->Variables.Set("MONK_STAGGER_PAUSE_UNTIL", uint32(GameTime::GetGameTimeMS() + pauseSec * IN_MILLISECONDS));
            uint32 const visualIds[3] = { SPELL_MONK_LIGHT_STAGGER, SPELL_MONK_MODERATE_STAGGER, SPELL_MONK_HEAVY_STAGGER };
            for (uint32 id : visualIds)
            {
                if (Aura* visual = caster->GetAura(id))
                {
                    visual->SetMaxDuration(visual->GetMaxDuration() + pauseSec * IN_MILLISECONDS);
                    visual->SetDuration(visual->GetDuration() + pauseSec * IN_MILLISECONDS);
                }
            }
            if (Aura* stagger = caster->GetAura(SPELL_MONK_STAGGER))
            {
                stagger->SetMaxDuration(stagger->GetMaxDuration() + pauseSec * IN_MILLISECONDS);
                stagger->SetDuration(stagger->GetDuration() + pauseSec * IN_MILLISECONDS);
            }
            caster->RemoveAura(SPELL_MONK_BLACKOUT_COMBO_BUFF);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_monk_ironskin_brew::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// 196736 - Blackout Combo. Aura 42 already Triggers 228563 — do not Cast it.
class spell_monk_blackout_combo : public AuraScript
{
    PrepareAuraScript(spell_monk_blackout_combo);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_BLACKOUT_COMBO_BUFF });
    }

    void Register() override
    {
    }
};

// 100784 - Blackout Kick. Dummy 0/1000 are not script constants. 3000 ms is not a Dummy.
class spell_monk_blackout_kick : public SpellScript
{
    PrepareSpellScript(spell_monk_blackout_kick);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_BLACKOUT_KICK_PROC });
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        if (caster->HasAura(SPELL_MONK_BLACKOUT_KICK_PROC))
            caster->RemoveAurasDueToSpell(SPELL_MONK_BLACKOUT_KICK_PROC);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_monk_blackout_kick::HandleHit);
    }
};

// 101546 - Spinning Crane Kick. Dummy 15 is not a percent. +10% is 220358 Aura 108.
class spell_monk_spinning_crane_kick : public AuraScript
{
    PrepareAuraScript(spell_monk_spinning_crane_kick);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_MARK_OF_THE_CRANE, SPELL_MONK_CYCLONE_STRIKES_BUFF, SPELL_MONK_SPINNING_CRANE_KICK_DAMAGE });
    }

    void HandlePeriodic(AuraEffect const* /*aurEff*/)
    {
        Unit* caster = GetTarget();
        if (!caster)
            return;

        float radius = 8.0f;
        if (SpellInfo const* dmg = sSpellMgr->GetSpellInfo(SPELL_MONK_SPINNING_CRANE_KICK_DAMAGE))
            if (SpellEffectInfo const* eff = dmg->GetEffect(EFFECT_0))
                radius = eff->CalcRadius(caster);

        std::list<Unit*> targets;
        caster->GetAttackableUnitListInRange(targets, radius);
        uint32 marked = 0;
        for (Unit* unit : targets)
        {
            if (!caster->IsValidAttackTarget(unit))
                continue;
            caster->CastSpell(unit, SPELL_MONK_MARK_OF_THE_CRANE, true);
            ++marked;
            if (marked >= 5) // non-DBC observation window
                break;
        }

        uint32 uniqueMarks = 0;
        std::list<Unit*> counted;
        caster->GetAttackableUnitListInRange(counted, 40.0f);
        for (Unit* unit : counted)
            if (unit->HasAura(SPELL_MONK_MARK_OF_THE_CRANE, caster->GetGUID()))
                ++uniqueMarks;
        if (uniqueMarks > 5)
            uniqueMarks = 5;
        if (uniqueMarks == 0)
            return;

        caster->CastSpell(caster, SPELL_MONK_CYCLONE_STRIKES_BUFF, true);
        if (Aura* cyclone = caster->GetAura(SPELL_MONK_CYCLONE_STRIKES_BUFF))
            cyclone->SetStackAmount(uint8(uniqueMarks));
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_spinning_crane_kick::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

// 152173 - Serenity. No Dummy. Talent Overrides 137639. Do not force SEF.
class spell_monk_serenity : public AuraScript
{
    PrepareAuraScript(spell_monk_serenity);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_SEF });
    }

    void Register() override
    {
    }
};

// 261947 - Fist of the White Tiger. Damage AP 0.8775 and chi Energize are on SpellInfo.
class spell_monk_fist_of_the_white_tiger : public SpellScript
{
    PrepareSpellScript(spell_monk_fist_of_the_white_tiger);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_FIST_OF_THE_WHITE_TIGER });
    }

    void Register() override
    {
    }
};

// 116847 - Rushing Jade Wind. Aura 23 already Triggers 148187. Dummy 2 is not jump count.
class spell_monk_rushing_jade_wind : public AuraScript
{
    PrepareAuraScript(spell_monk_rushing_jade_wind);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_RUSHING_JADE_WIND_DAMAGE });
    }

    void Register() override
    {
    }
};

// 196740 - Hit Combo. Dummy 0 is not a proc rate. 196741 max 6 / 10s is AuraOptions.
class spell_monk_hit_combo : public AuraScript
{
    PrepareAuraScript(spell_monk_hit_combo);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_HIT_COMBO_BUFF });
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        Unit* caster = GetTarget();
        if (!caster || !eventInfo.GetSpellInfo())
            return;

        uint32 id = eventInfo.GetSpellInfo()->Id;
        uint32 last = caster->Variables.GetValue<uint32>("MONK_HIT_COMBO_LAST", 0);
        if (last && id == last)
        {
            caster->RemoveAurasDueToSpell(SPELL_MONK_HIT_COMBO_BUFF);
            caster->Variables.Remove("MONK_HIT_COMBO_LAST");
            return;
        }
        caster->Variables.Set("MONK_HIT_COMBO_LAST", id);
        caster->CastSpell(caster, SPELL_MONK_HIT_COMBO_BUFF, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_monk_hit_combo::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// 261767 - Inner Strength. Dummy 25 is not 5x5. Stacks come from 261769 AuraOptions.
class spell_monk_inner_strength : public AuraScript
{
    PrepareAuraScript(spell_monk_inner_strength);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_INNER_STRENGTH_BUFF });
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        Spell const* procSpell = eventInfo.GetProcSpell();
        if (!procSpell)
            return;
        SpellPowerCost const* cost = procSpell->GetPowerCost(POWER_CHI);
        if (!cost || cost->Amount <= 0)
            return;
        GetTarget()->CastSpell(GetTarget(), SPELL_MONK_INNER_STRENGTH_BUFF, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_monk_inner_strength::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// 280197 - Spiritual Focus. Dummy 2 chi / Dummy 1000 ms. Do not write a 1-second constant.
class spell_monk_spiritual_focus : public AuraScript
{
    PrepareAuraScript(spell_monk_spiritual_focus);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_SEF });
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        Unit* caster = GetTarget();
        Spell const* procSpell = eventInfo.GetProcSpell();
        if (!caster || !procSpell)
            return;

        SpellPowerCost const* cost = procSpell->GetPowerCost(POWER_CHI);
        if (!cost || cost->Amount <= 0)
            return;

        SpellEffectInfo const* dummy2 = GetSpellInfo()->GetEffect(EFFECT_0);
        SpellEffectInfo const* dummy1000 = GetSpellInfo()->GetEffect(EFFECT_1);
        if (!dummy2 || !dummy1000)
            return;

        int32 chiPer = dummy2->CalcValue(caster);
        if (chiPer <= 0)
            return;

        int32 reduce = dummy1000->CalcValue(caster) * (cost->Amount / chiPer);
        if (reduce <= 0)
            return;

        if (SpellInfo const* sef = sSpellMgr->GetSpellInfo(SPELL_MONK_SEF))
            caster->GetSpellHistory()->ReduceChargeCooldown(sef->ChargeCategoryId, uint32(reduce));
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_monk_spiritual_focus::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

// 116680 - Thunder Focus Tea. Focused Thunder 197895 is two applications, not a separate script class.
class spell_monk_thunder_focus_tea : public AuraScript
{
    PrepareAuraScript(spell_monk_thunder_focus_tea);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
        {
            SPELL_MONK_RISING_SUN_KICK,
            SPELL_MONK_RENEWING_MIST,
            SPELL_MONK_ENVELOPING_MIST,
            SPELL_MONK_VIVIFY,
            SPELL_MONK_TFT_ENVELOP_HEAL
        });
    }

    void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        if (GetTarget()->HasAura(SPELL_MONK_FOCUSED_THUNDER))
            GetAura()->SetStackAmount(2);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!eventInfo.GetSpellInfo())
            return false;
        uint32 id = eventInfo.GetSpellInfo()->Id;
        return id == SPELL_MONK_RISING_SUN_KICK
            || id == SPELL_MONK_RENEWING_MIST
            || id == SPELL_MONK_ENVELOPING_MIST
            || id == SPELL_MONK_VIVIFY;
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        Unit* caster = GetTarget();
        if (!caster)
            return;

        if (eventInfo.GetSpellInfo() && eventInfo.GetSpellInfo()->Id == SPELL_MONK_ENVELOPING_MIST)
        {
            Unit* healTarget = eventInfo.GetActionTarget();
            if (!healTarget)
                healTarget = eventInfo.GetProcTarget();
            if (!healTarget)
                healTarget = caster;
            caster->CastSpell(healTarget, SPELL_MONK_TFT_ENVELOP_HEAL, true);
        }

        if (GetAura()->GetStackAmount() > 1)
            GetAura()->SetStackAmount(GetAura()->GetStackAmount() - 1);
        else
            Remove();
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_monk_thunder_focus_tea::HandleApply, EFFECT_0, SPELL_AURA_ADD_FLAT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
        DoCheckProc += AuraCheckProcFn(spell_monk_thunder_focus_tea::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_monk_thunder_focus_tea::HandleProc, EFFECT_0, SPELL_AURA_ADD_FLAT_MODIFIER);
    }
};

// 198756 - Crane Heal. Three injured allies is a non-DBC observation window.
class spell_monk_chi_ji_heal : public SpellScript
{
    PrepareSpellScript(spell_monk_chi_ji_heal);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_CHI_JI_HEAL });
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        if (caster->Variables.GetValue<uint32>("MONK_CHI_JI_EXPANDING", 0))
            return;

        caster->Variables.Set("MONK_CHI_JI_EXPANDING", 1u);

        std::list<Unit*> allies;
        caster->GetFriendlyUnitListInRange(allies, 40.0f, false);
        Unit* original = GetExplTargetUnit();
        allies.remove_if([original](Unit* unit)
        {
            return !unit || unit->IsFullHealth() || unit == original;
        });
        if (allies.size() > 2)
        {
            allies.sort(Trinity::HealthPctOrderPred());
            allies.resize(2);
        }
        for (Unit* ally : allies)
            caster->CastSpell(ally, SPELL_MONK_CHI_JI_HEAL, true);

        caster->Variables.Set("MONK_CHI_JI_EXPANDING", 0u);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_monk_chi_ji_heal::HandleAfterCast);
    }
};

// 274963 - Upwelling. Aura 107 +4000 ms for 191840 is on the table; do not add it in script.
class spell_monk_upwelling : public AuraScript
{
    PrepareAuraScript(spell_monk_upwelling);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_ESSENCE_FONT });
    }

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        Unit* caster = GetTarget();
        if (!caster)
            return;

        if (Spell* channel = caster->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            if (channel->GetSpellInfo()->Id == SPELL_MONK_ESSENCE_FONT)
                return;

        int32 dummy6 = aurEff->GetAmount();
        if (dummy6 <= 0)
            dummy6 = 6;

        int32 ticks = caster->Variables.GetValue<int32>("MONK_UPWELLING_TICKS", 0) + 1;
        if (ticks >= dummy6)
        {
            ticks = 0;
            int32 extra = caster->Variables.GetValue<int32>("MONK_UPWELLING_EXTRA_MS", 0) + IN_MILLISECONDS;
            caster->Variables.Set("MONK_UPWELLING_EXTRA_MS", extra);
        }
        caster->Variables.Set("MONK_UPWELLING_TICKS", ticks);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_monk_upwelling::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// 196725 - Refreshing Jade Wind (Mistweaver). Not the same function as 116847.
class spell_monk_rushing_jade_wind_mw : public AuraScript
{
    PrepareAuraScript(spell_monk_rushing_jade_wind_mw);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_MONK_RUSHING_JADE_WIND_MW_DAMAGE });
    }

    void Register() override
    {
    }
};

void AddSC_monk_spell_scripts()
{
    RegisterAreaTriggerAI(at_monk_gift_of_the_ox_sphere);
    RegisterAreaTriggerAI(at_monk_windwalking);
    RegisterAreaTriggerAI(at_monk_chi_burst_damage);
    RegisterAreaTriggerAI(at_monk_chi_burst_heal);
    RegisterAreaTriggerAI(at_monk_song_of_chiji);
    new spell_monk_vivify();
    new spell_monk_black_ox_brew();
    new spell_monk_breath_of_fire();
    new spell_monk_chi_burst_heal();
    new spell_monk_chi_wave();
    new spell_monk_chi_wave_damage_missile();
    new spell_monk_chi_wave_heal_missile();
    new spell_monk_chi_wave_healing_bolt();
    new spell_monk_crackling_jade_knockback();
    new spell_monk_crackling_jade_lightning();
    new spell_monk_crackling_jade_lightning_knockback_proc_aura();
    new spell_monk_dampen_harm();
    RegisterSpellAndAuraScriptPair(spell_monk_disable, aura_monk_disable);
    RegisterAuraScript(spell_monk_elusive_brawler_mastery);
    RegisterAuraScript(spell_monk_elusive_brawler_stacks);
    new spell_monk_energizing_brew();
    new spell_monk_enveloping_mist();
    new spell_monk_essence_font_heal();
    new spell_monk_expel_harm();
    new spell_monk_fists_of_fury();
    new spell_monk_fists_of_fury_damage();
    //new spell_monk_fists_of_fury_stun();
    new spell_monk_fists_of_fury_visual();
    new spell_monk_fists_of_fury_visual_filter();
    new spell_monk_flying_serpent_kick();
    new spell_monk_fortifying_brew();
    new spell_monk_gift_of_the_ox_aura();
    new spell_monk_guard();
    new spell_monk_healing_elixirs_aura();
    new spell_monk_item_s12_4p_mistweaver();
    new spell_monk_jab();
    new spell_monk_jade_serpent_statue();
    new spell_monk_keg_smash();
    new spell_monk_legacy_of_the_emperor();
    new spell_monk_lifecycles();
    new spell_monk_life_cocoon();
    new spell_monk_mana_tea();
    new spell_monk_mana_tea_stacks();
    RegisterAuraScript(spell_monk_path_of_blossom);
    new spell_monk_power_strikes();
    new spell_monk_provoke();
    new spell_monk_purifying_brew();
    RegisterSpellScript(spell_monk_renewing_mist);
    RegisterAuraScript(spell_monk_renewing_mist_hot);
    RegisterSpellScript(spell_monk_renewing_mist_jump);
    RegisterAuraScript(spell_monk_spirit_of_the_crane_passive);
    RegisterAuraScript(spell_monk_way_of_the_crane);
    new spell_monk_ring_of_peace_aura();
    RegisterSpellScript(spell_monk_rising_sun_kick);
    new spell_monk_rising_thunder();
    new spell_monk_roll();
    new spell_monk_roll_trigger();
    new spell_monk_soothing_mist();
    new spell_monk_soothing_mist_aura();
    new spell_monk_spear_hand_strike();
    new spell_monk_stagger_damage();
    new spell_monk_stagger_visual();
    new spell_monk_stance_of_the_sturdy_ox();
    RegisterAuraScript(spell_monk_storm_earth_and_fire);
    new spell_monk_surging_mist();
    new spell_monk_surging_mist_glyphed();
    RegisterAuraScript(spell_monk_teachings_of_the_monastery_buff);
    RegisterAuraScript(spell_monk_teachings_of_the_monastery_passive);
    new spell_monk_tiger_lust();
    new spell_monk_tigereye_brew_stacks();
    RegisterAuraScript(spell_monk_touch_of_death);
    new spell_monk_touch_of_karma();
    RegisterAuraScript(spell_monk_touch_of_karma_buff);
    RegisterSpellScript(spell_monk_transcendence);
    RegisterSpellScript(spell_monk_transcendence_transfer);
    new spell_monk_zen_flight_check();
    new spell_monk_zen_pilgrimage();
    new spell_monk_zen_pulse();
    new playerScript_monk_whirling_dragon_punch();
    RegisterAuraScript(spell_monk_whirling_dragon_punch);
    RegisterSpellScript(spell_monk_tiger_palm);
    RegisterAuraScript(spell_monk_touch_of_death_amplifier);
    RegisterAuraScript(spell_monk_touch_of_death_passive);
    RegisterCreatureAI(npc_monk_sef_spirit);
    RegisterCreatureAI(npc_monk_xuen);
	new spell_monk_zen_pilgrimage_return();
    RegisterCreatureAI(npc_monk_jade_serpent_statue);
    RegisterAreaTriggerAI(at_monk_ring_of_peace);
    RegisterPlayerScript(mystic_touch);
    RegisterSpellScript(spell_monk_essence_font);
    RegisterAuraScript(aura_monk_transcendence);
    new spell_monk_chi_wave_target_selector();
    new playerScript_monk_earth_fire_storm();
    RegisterSpellScript(spell_monk_ironskin_brew);
    RegisterAuraScript(spell_monk_blackout_combo);
    RegisterSpellScript(spell_monk_blackout_kick);
    RegisterAuraScript(spell_monk_spinning_crane_kick);
    RegisterAuraScript(spell_monk_serenity);
    RegisterSpellScript(spell_monk_fist_of_the_white_tiger);
    RegisterAuraScript(spell_monk_rushing_jade_wind);
    RegisterAuraScript(spell_monk_hit_combo);
    RegisterAuraScript(spell_monk_inner_strength);
    RegisterAuraScript(spell_monk_spiritual_focus);
    RegisterAuraScript(spell_monk_thunder_focus_tea);
    RegisterSpellScript(spell_monk_chi_ji_heal);
    RegisterAuraScript(spell_monk_upwelling);
    RegisterAuraScript(spell_monk_rushing_jade_wind_mw);
}
