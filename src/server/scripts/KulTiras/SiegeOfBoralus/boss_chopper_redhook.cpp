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
#include "siege_of_boralus.h"

const Position pos = { };

enum Texts
{
	SAY_HOOK = 0,
	SAY_INCOMING,
	SAY_GORE
};

enum Events
{
	EVENT_GORE_CRASH = 1,
	EVENT_ON_THE_HOOK,
	EVENT_BARRAGE,
	EVENT_SIGHTED_ARTILLERY,
};

enum Spells
{
	ON_THE_HOOK = 257459,
	HEAVY_HITTER = 256867,
	GORE_CRASH = 257326,
	MEAT_HOOK_STALKER = 257340,
	MEAT_HOOK_SPAWN_EFFECT = 257342,
	MEAT_HOOK_STUN = 257354,
	BOILING_RAGE = 257650,
	CANNON_BARRAGE = 257585,
	SIGHTED_ARTILLERY = 272425,
};

//128650 Chopper Redhook; Bainbridge is boss_sergeant_bainbridge
struct boss_chopper_redhook : public BossAI
{
	boss_chopper_redhook(Creature* creature) : BossAI(creature, DATA_CHOPPER_REDHOOK) { }

	void Reset() override
	{
		BossAI::Reset();		
	}

	void EnterCombat(Unit* /*unit*/) override
	{
		_EnterCombat();
		events.ScheduleEvent(EVENT_GORE_CRASH, 1s);
		events.ScheduleEvent(EVENT_ON_THE_HOOK, 3s);
		events.ScheduleEvent(EVENT_SIGHTED_ARTILLERY, 6s); // was DoCast(272425); Sighted Artillery, not Cannon Barrage
		events.ScheduleEvent(EVENT_BARRAGE, 8s); // 257585 min-playable, not plugin CD 11/60
	}

	void JustDied(Unit* /*killer*/) override
	{
		_JustDied();
	}

	void ExecuteEvent(uint32 eventid) override
	{
		switch (eventid)
		{
		case EVENT_GORE_CRASH:	
			if (me->GetDistance(me->GetVictim()))
			{
				Talk(SAY_GORE);
				DoCastVictim(GORE_CRASH);
			}	
			events.Repeat(15s);
			break;

		case EVENT_ON_THE_HOOK:
			if (Unit* tar = SelectTarget(SELECT_TARGET_FARTHEST, 0, 100.0f, true))
			{
				Talk(SAY_HOOK);
				me->RemoveAurasDueToSpell(HEAVY_HITTER);
				me->AddAura(ON_THE_HOOK, tar);
				me->AddThreat(tar, 100.0f, SPELL_SCHOOL_MASK_NORMAL);	
				me->SetWalk(false);
				me->SetSpeedRate(MOVE_RUN, 0.5f);
				if (!me->HasAura(BOILING_RAGE))
				{
					me->CastSpell(me, BOILING_RAGE);
				}				
				me->GetMotionMaster()->MoveChase(tar, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
			}		
			events.Repeat(15s);
			break;

		case EVENT_SIGHTED_ARTILLERY:
		{
			std::list<Player*> p_list;
			me->GetPlayerListInGrid(p_list, 300.0f);
			for (auto & p : p_list)
			DoCast(p, SIGHTED_ARTILLERY);
		}
		events.Repeat(20s); // existing timing for 272425, not plugin CD
		break;

		case EVENT_BARRAGE:
			Talk(SAY_INCOMING);
			DoCast(CANNON_BARRAGE);
			events.Repeat(25s); // min-playable, not plugin CD 60
			break;

		default:
			break;
		}
	}
};

//129765
struct npc_meat_hook_target_stalker : public ScriptedAI
{
	npc_meat_hook_target_stalker(Creature* c) : ScriptedAI(c) { }

	void Reset() override
	{
		ScriptedAI::Reset();
		me->SetReactState(REACT_PASSIVE);
		me->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_PC);
		me->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
		me->AddUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
		me->CastSpell(me, MEAT_HOOK_SPAWN_EFFECT);
	}
};

enum BainbridgeEvents
{
	EVENT_IRON_GAZE = 1,
	EVENT_HANGMANS_NOOSE,
	EVENT_STEEL_TEMPEST,
	EVENT_BAINBRIDGE_BARRAGE,
};

enum BainbridgeSpells
{
	IRON_GAZE = 260954,
	HANGMANS_NOOSE = 261428,
	STEEL_TEMPEST = 260924,
	BAINBRIDGE_CANNON_BARRAGE = 257585,
};

//128649 Sergeant Bainbridge; do not bind DATA_CHOPPER_REDHOOK
struct boss_sergeant_bainbridge : public BossAI
{
	boss_sergeant_bainbridge(Creature* creature) : BossAI(creature, DATA_SERGEANT_BAINBRIDGE) { }

	void Reset() override
	{
		BossAI::Reset();
	}

	void EnterCombat(Unit* /*unit*/) override
	{
		_EnterCombat();
		events.ScheduleEvent(EVENT_IRON_GAZE, 5s); // min-playable, not plugin CD
		events.ScheduleEvent(EVENT_HANGMANS_NOOSE, 10s);
		events.ScheduleEvent(EVENT_STEEL_TEMPEST, 8s);
		events.ScheduleEvent(EVENT_BAINBRIDGE_BARRAGE, 8s);
	}

	void JustDied(Unit* /*killer*/) override
	{
		_JustDied();
	}

	void ExecuteEvent(uint32 eventid) override
	{
		switch (eventid)
		{
		case EVENT_IRON_GAZE:
			if (Unit* tar = SelectTarget(SELECT_TARGET_RANDOM, 0, 100.0f, true))
				DoCast(tar, IRON_GAZE);
			events.Repeat(20s); // min-playable, not plugin CD
			break;
		case EVENT_HANGMANS_NOOSE:
			if (Unit* tar = SelectTarget(SELECT_TARGET_RANDOM, 0, 100.0f, true))
				DoCast(tar, HANGMANS_NOOSE);
			events.Repeat(15s);
			break;
		case EVENT_STEEL_TEMPEST:
			DoCast(STEEL_TEMPEST);
			events.Repeat(18s);
			break;
		case EVENT_BAINBRIDGE_BARRAGE:
			DoCast(BAINBRIDGE_CANNON_BARRAGE);
			events.Repeat(25s);
			break;
		default:
			break;
		}
	}
};

void AddSC_boss_chopper_redhook()
{
	RegisterCreatureAI(boss_chopper_redhook);
	RegisterCreatureAI(npc_meat_hook_target_stalker);
	RegisterCreatureAI(boss_sergeant_bainbridge);
}
