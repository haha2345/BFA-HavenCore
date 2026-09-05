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

#include "ScriptMgr.h"
#include "tol_dagor.h"

enum Spells {
    SPELL_CRIP_SHIV = 257777,
    SPELL_HOWLING_FEAR = 257791,
    SPELL_FLASHING_DAGGER = 257785,
    SPELL_SMOKE_POWDER = 257793,
    SPELL_MOTIVATING_CRY = 257827,
    SPELL_RELEASE_PRISONER = 257814,
    SPELL_RELEASING = 258544,
};

enum Events {
    EVENT_CRIP_SHIV = 1,
    EVENT_HOWLING_FEAR = 2,
    EVENT_FLASHING_DAGGER = 3,
    EVENT_SMOKE_POWDER = 4,
    EVENT_RELEASE_PRISONERS = 5,
    EVENT_MOTIVATING_CRY = 6,
};

//jes howlis 127484
struct boss_jes_howlis : public BossAI
{
    boss_jes_howlis(Creature* creature) : BossAI(creature, DATA_JES_HOWLIS), _smokeUsed(false), _rotationPaused(false) { }

    void InitializeAI() override
    {
        BossAI::InitializeAI();
    }

    void Reset() override
    {
        BossAI::Reset();
        _smokeUsed = false;
        _rotationPaused = false;
    }

    void EnterCombat(Unit* who) override
    {
        Talk(0);
        events.ScheduleEvent(EVENT_CRIP_SHIV, 7200);
        events.ScheduleEvent(EVENT_HOWLING_FEAR, 8500);
        events.ScheduleEvent(EVENT_FLASHING_DAGGER, 12100);
        BossAI::EnterCombat(who);
    }

    void SpellHitTarget(Unit* /*target*/, SpellInfo const* /*spell*/) override
    {
    }

    void DamageTaken(Unit* attacker, uint32& damage) override
    {
        // 50% is 2018 min-playable, not verified 8.3 EventMap; do not use retail 70%
        if (!_smokeUsed && me->HealthBelowPctDamaged(50, damage))
        {
            _smokeUsed = true;
            events.ScheduleEvent(EVENT_SMOKE_POWDER, 0);
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        if (_rotationPaused
            && !events.HasEvent(EVENT_RELEASE_PRISONERS) && !events.HasEvent(EVENT_MOTIVATING_CRY)
            && me->FindCurrentSpellBySpellId(SPELL_MOTIVATING_CRY) == nullptr
            && !me->HasAura(SPELL_MOTIVATING_CRY))
        {
            _rotationPaused = false;
            events.ScheduleEvent(EVENT_CRIP_SHIV, 7200);
            events.ScheduleEvent(EVENT_HOWLING_FEAR, 8500);
            events.ScheduleEvent(EVENT_FLASHING_DAGGER, 12100);
        }

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
            case EVENT_CRIP_SHIV:
                DoCastVictim(SPELL_CRIP_SHIV);
                events.ScheduleEvent(EVENT_CRIP_SHIV, 16100);
                break;
            case EVENT_HOWLING_FEAR:
                DoCastVictim(SPELL_HOWLING_FEAR);
                events.ScheduleEvent(EVENT_HOWLING_FEAR, 13400);
                break;
            case EVENT_FLASHING_DAGGER:
                Talk(1);
                DoCastVictim(SPELL_FLASHING_DAGGER);
                events.ScheduleEvent(EVENT_FLASHING_DAGGER, 31600);
                break;
            case EVENT_SMOKE_POWDER:
                me->CastSpell(me, SPELL_SMOKE_POWDER);
                _rotationPaused = true;
                events.CancelEvent(EVENT_CRIP_SHIV);
                events.CancelEvent(EVENT_HOWLING_FEAR);
                events.CancelEvent(EVENT_FLASHING_DAGGER);
                events.ScheduleEvent(EVENT_RELEASE_PRISONERS, 1500); // 1500ms is intermission glue, not addon CD
                break;
            case EVENT_RELEASE_PRISONERS:
                Talk(3);
                me->CastSpell(me, SPELL_RELEASE_PRISONER);
                if (IsTolDagorHeroicPlus(me->GetMap()))
                {
                    Talk(4);
                    me->CastSpell(me, SPELL_RELEASING);
                }
                events.ScheduleEvent(EVENT_MOTIVATING_CRY, 1500);
                break;
            case EVENT_MOTIVATING_CRY:
                me->CastSpell(me, SPELL_MOTIVATING_CRY);
                break;
            default:
                break;
            }
        }

        DoMeleeAttackIfReady();
    }
private:
    bool _smokeUsed;
    bool _rotationPaused;
};

void AddSC_boss_jes_howlis()
{
    RegisterCreatureAI(boss_jes_howlis);
}
