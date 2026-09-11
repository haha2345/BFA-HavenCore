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

#include "AreaBoundary.h"
#include "Creature.h"
#include "CellImpl.h"
#include "GameEventMgr.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "Player.h"
#include "ScriptedGossip.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "World.h"
#include "InstanceScript.h"
#include "freehold.h"
#include <list>

// Dump spawn coords (map 1754): Kragg ship, council bar, ring pit, Harlan deck.
// Circle + Z-range are AND-ed by BossAI::CheckBoundary / CanAIAttack.
BossBoundaryData const freeholdBoundaries =
{
    { FreeholdData::DataSkycapKragg,      new CircleBoundary(Position(-1778.22f, -994.856f), 55.0) },
    { FreeholdData::DataSkycapKragg,      new ZRangeBoundary(70.0f, 120.0f) },
    { FreeholdData::DataCounciloCaptains, new CircleBoundary(Position(-1778.89f, -685.425f), 32.0) },
    { FreeholdData::DataCounciloCaptains, new ZRangeBoundary(30.0f, 52.0f) },
    { FreeholdData::DataRingOfBooty,      new CircleBoundary(Position(-1813.17f, -491.82f), 40.0) },
    { FreeholdData::DataRingOfBooty,      new ZRangeBoundary(28.0f, 48.0f) },
    { FreeholdData::DataHarlanSweete,     new CircleBoundary(Position(-1587.22f, -562.097f), 55.0) },
    { FreeholdData::DataHarlanSweete,     new ZRangeBoundary(55.0f, 90.0f) },
};

static bool ShouldDisableGravityForFreeholdSpawn(uint32 entry)
{
    switch (entry)
    {
    case uint32(FreeholdCreature::NpcIrontideCrackshot):
    case uint32(FreeholdCreature::NpcIrontideCorsair):
        return true;
    default:
        return false;
    }
}

struct instance_free_hold : public InstanceScript
{
    instance_free_hold(InstanceMap* map) : InstanceScript(map) { }
    
        void Initialize() override
    {
        skycapGuid = ObjectGuid::Empty;
        sharkbaitGuid = ObjectGuid::Empty;
        jollyGuid = ObjectGuid::Empty;
        eudoraGuid = ObjectGuid::Empty;
        raoulGuid = ObjectGuid::Empty;
        lightningGuid = ObjectGuid::Empty;
        tortollanGuid = ObjectGuid::Empty;
        trothakGuid = ObjectGuid::Empty;
        harlanGuid = ObjectGuid::Empty;
        gukgukGuid = ObjectGuid::Empty;
        gurgthockGuid = ObjectGuid::Empty;
        daveyGuid = ObjectGuid::Empty;
        captainsControllerGuid = ObjectGuid::Empty;
        SetHeaders(DataHeader);
        SetBossNumber(FreeholdData::DataMaxEncounters);
        LoadBossBoundaries(freeholdBoundaries);
    }

    void OnCreatureCreate(Creature* creature) override
    {
        switch (creature->GetEntry())
        {
        case uint32(FreeholdCreature::NpcSkycapKragg):
            skycapGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcSharkBaitBoss):
            sharkbaitGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcCaptainJolly):
            jollyGuid = creature->GetGUID();
            ApplyWeeklyCouncilAlliance();
            break;
        case uint32(FreeholdCreature::NpcCaptainEudora):
            eudoraGuid = creature->GetGUID();
            ApplyWeeklyCouncilAlliance();
            break;
        case uint32(FreeholdCreature::NpcCaptainRaoul):
            raoulGuid = creature->GetGUID();
            ApplyWeeklyCouncilAlliance();
            break;
        case uint32(FreeholdCreature::NpcGukguk):
            gukgukGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcGurgthock):
            gurgthockGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcDavey):
            daveyGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcLightning):
            lightningGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcLudwigVonTortollan):
            tortollanGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcTrothak):
            trothakGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcHarlanSweete):
            harlanGuid = creature->GetGUID();
            break;
        case uint32(FreeholdCreature::NpcCaptainsController):
            captainsControllerGuid = creature->GetGUID();
            break;
        default:
            break;
        }

        // Task 13 tent stalls only. Whole-map DisableGravity let bosses walk off decks.
        if (ShouldDisableGravityForFreeholdSpawn(creature->GetEntry()))
        {
            Position const home = creature->GetHomePosition();
            creature->Relocate(home);
            creature->SetDisableGravity(true);
        }
    }

    void OnPlayerEnter(Player* /*player*/) override
    {
        ApplyWeeklyCouncilAlliance();
    }

    uint32 GetEffectiveFriendlyCaptainEntry() const
    {
        if (GetData(uint32(FreeholdData::DataCrewEventDone)) != 0)
        {
            uint32 const saved = GetData(uint32(FreeholdData::DataFriendlyCaptain));
            if (saved)
                return saved;
        }

        switch (GetActiveFreeholdCrewWeek())
        {
        case CrewWeekBlacktooth:
            return uint32(FreeholdCreature::NpcCaptainRaoul);
        case CrewWeekBilgeRats:
            return uint32(FreeholdCreature::NpcCaptainEudora);
        case CrewWeekCutwater:
        case CrewWeekNone:
        default:
            return uint32(FreeholdCreature::NpcCaptainJolly);
        }
    }

    void ApplyWeeklyCouncilAlliance()
    {
        if (GetBossState(FreeholdData::DataCounciloCaptains) == DONE)
            return;

        uint32 const friendlyEntry = GetEffectiveFriendlyCaptainEntry();
        Creature* captain = nullptr;
        int32 action = 0;
        switch (friendlyEntry)
        {
        case uint32(FreeholdCreature::NpcCaptainJolly):
            captain = instance->GetCreature(jollyGuid);
            action = FreeholdAction::ActionSelectCaptainJolly;
            break;
        case uint32(FreeholdCreature::NpcCaptainRaoul):
            captain = instance->GetCreature(raoulGuid);
            action = FreeholdAction::ActionSelectCaptainRaoul;
            break;
        case uint32(FreeholdCreature::NpcCaptainEudora):
            captain = instance->GetCreature(eudoraGuid);
            action = FreeholdAction::ActionSelectCaptainEudora;
            break;
        default:
            break;
        }

        if (captain && captain->AI())
            captain->AI()->DoAction(action);
    }

    ObjectGuid GetGuidData(uint32 type) const override
    {
        switch (type)
        {
        case uint32(FreeholdCreature::NpcSkycapKragg):
            return skycapGuid;
            break;
        case uint32(FreeholdCreature::NpcSharkBaitBoss):
            return sharkbaitGuid;
            break;
        case uint32(FreeholdCreature::NpcCaptainJolly):
            return jollyGuid;
            break;
        case uint32(FreeholdCreature::NpcCaptainEudora):
            return eudoraGuid;
            break;
        case uint32(FreeholdCreature::NpcCaptainRaoul):
            return raoulGuid;
            break;
        case uint32(FreeholdCreature::NpcGukguk):
            return gukgukGuid;
            break;
        case uint32(FreeholdCreature::NpcGurgthock):
            return gurgthockGuid;
            break;
        case uint32(FreeholdCreature::NpcDavey):
            return daveyGuid;
            break;
        case uint32(FreeholdCreature::NpcLightning):
            return lightningGuid;
            break;
        case uint32(FreeholdCreature::NpcLudwigVonTortollan):
            return tortollanGuid;
            break;
        case uint32(FreeholdCreature::NpcTrothak):
            return trothakGuid;
            break;
        case uint32(FreeholdCreature::NpcHarlanSweete):
            return harlanGuid;
            break;
        case DataCaptainsController:
            return captainsControllerGuid;
        default:
            break;
        }

        return ObjectGuid::Empty;
    }

    // Haven private Freehold crew-week calendar (not 8.3 DBC). User confirmed 2026-08-30: 209/210/211.
    FreeholdCrewWeek GetActiveFreeholdCrewWeek() const
    {
        if (sGameEventMgr->IsActiveEvent(209))
            return CrewWeekCutwater;
        if (sGameEventMgr->IsActiveEvent(210))
            return CrewWeekBlacktooth;
        if (sGameEventMgr->IsActiveEvent(211))
            return CrewWeekBilgeRats;
        return CrewWeekNone;
    }

    void NotifyCrewEventComplete(uint32 captainEntry)
    {
        SetData(uint32(FreeholdData::DataCrewEventDone), 1);
        SetData(uint32(FreeholdData::DataFriendlyCaptain), captainEntry);

        Creature* captain = nullptr;
        int32 action = 0;
        uint32 const* crewEntries = nullptr;
        uint8 crewCount = 0;

        static uint32 const CutwaterCrew[] =
        {
            uint32(FreeholdCreature::NpcCutwaterDuelist),
            uint32(FreeholdCreature::NpcCutwaterKnifeJuggler),
            uint32(FreeholdCreature::NpcCutwaterHarpooner),
            uint32(FreeholdCreature::NpcCaptainJolly)
        };
        static uint32 const BlacktoothCrew[] =
        {
            uint32(FreeholdCreature::NpcBlacktoothBrutes),
            uint32(FreeholdCreature::NpcBlacktoothScrapper),
            uint32(FreeholdCreature::NpcBlacktoothKnuckleduster),
            uint32(FreeholdCreature::NpcCaptainRaoul)
        };
        static uint32 const BilgeRatsCrew[] =
        {
            uint32(FreeholdCreature::NpcBilgeRatPadfoot),
            uint32(FreeholdCreature::NpcBilgeRatBuccaneer),
            uint32(FreeholdCreature::NpcBilgeRatBrinescale),
            uint32(FreeholdCreature::NpcBilgeRatSwabby),
            uint32(FreeholdCreature::NpcCaptainEudora)
        };

        switch (captainEntry)
        {
        case uint32(FreeholdCreature::NpcCaptainJolly):
            captain = instance->GetCreature(jollyGuid);
            action = FreeholdAction::ActionSelectCaptainJolly;
            crewEntries = CutwaterCrew;
            crewCount = uint8(sizeof(CutwaterCrew) / sizeof(CutwaterCrew[0]));
            break;
        case uint32(FreeholdCreature::NpcCaptainRaoul):
            captain = instance->GetCreature(raoulGuid);
            action = FreeholdAction::ActionSelectCaptainRaoul;
            crewEntries = BlacktoothCrew;
            crewCount = uint8(sizeof(BlacktoothCrew) / sizeof(BlacktoothCrew[0]));
            break;
        case uint32(FreeholdCreature::NpcCaptainEudora):
            captain = instance->GetCreature(eudoraGuid);
            action = FreeholdAction::ActionSelectCaptainEudora;
            crewEntries = BilgeRatsCrew;
            crewCount = uint8(sizeof(BilgeRatsCrew) / sizeof(BilgeRatsCrew[0]));
            break;
        default:
            break;
        }

        if (captain && captain->AI())
            captain->AI()->DoAction(action);

        if (!captain || !crewEntries)
            return;

        for (uint8 i = 0; i < crewCount; ++i)
        {
            std::list<Creature*> list;
            captain->GetCreatureListWithEntryInGrid(list, crewEntries[i], 200.0f);
            for (Creature* creature : list)
                if (creature)
                    creature->SetFaction(uint32(FreeHoldFaction::FactionFriendlyFake));
        }
    }

    ObjectGuid skycapGuid;
    ObjectGuid sharkbaitGuid;
    ObjectGuid jollyGuid;
    ObjectGuid eudoraGuid;
    ObjectGuid raoulGuid;
    ObjectGuid lightningGuid;
    ObjectGuid tortollanGuid;
    ObjectGuid trothakGuid;
    ObjectGuid harlanGuid;
    ObjectGuid gukgukGuid;
    ObjectGuid gurgthockGuid;
    ObjectGuid daveyGuid;
    ObjectGuid captainsControllerGuid;
};

// 9000000 - NPC Teleporter Free Hold
class npc_free_hold_entrance_teleporter : public CreatureScript
{
public:
    npc_free_hold_entrance_teleporter() : CreatureScript("npc_free_hold_entrance_teleporter") { }
    struct npc_free_hold_entrance_teleporterAI : public ScriptedAI
    {
        npc_free_hold_entrance_teleporterAI(Creature* creature) : ScriptedAI(creature)
        {
            instance = me->GetInstanceScript();
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            std::list<Player*> targetList;
            GetPlayerListInGrid(targetList, me, 8.0f);

            if (!targetList.empty())
            {
                for (auto itr : targetList)
                {
                    if (Player* player = itr->ToPlayer())
                    {
                        if ((player->GetGroup() && player->GetGroup()->isRaidGroup()) || player->IsGameMaster())
                        {
                            uint32 playerMapID = player->GetMap()->GetId();

                            switch (playerMapID)
                            {
                            case 1643:
                                player->TeleportTo(1754, -1591.513f, -995.6175f, 73.85955f, 2.4204f, TELE_TO_NOT_LEAVE_COMBAT);
                                break;
                            case 1754:
                                player->TeleportTo(1643, -1576.46313f, -1298.69787f, 31.31189f, 5.513684f, TELE_TO_NOT_LEAVE_COMBAT);
                                break;
                            default:
                                break;
                            }
                        }
                    }
                }
            }
        }

    private:
        InstanceScript* instance;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_free_hold_entrance_teleporterAI(creature);
    }
};

FreeholdCrewWeek GetActiveFreeholdCrewWeek(InstanceScript const* instance)
{
    if (instance_free_hold const* fh = dynamic_cast<instance_free_hold const*>(instance))
        return fh->GetActiveFreeholdCrewWeek();
    return CrewWeekNone;
}

uint32 GetEffectiveFriendlyCaptainEntry(InstanceScript const* instance)
{
    if (instance_free_hold const* fh = dynamic_cast<instance_free_hold const*>(instance))
        return fh->GetEffectiveFriendlyCaptainEntry();
    return uint32(FreeholdCreature::NpcCaptainJolly);
}

void NotifyCrewEventComplete(InstanceScript* instance, uint32 captainEntry)
{
    if (instance_free_hold* fh = dynamic_cast<instance_free_hold*>(instance))
        fh->NotifyCrewEventComplete(captainEntry);
}

enum FreeholdInstanceSpells
{
    SpellRatTrapsRoot = 274389
};

class spell_freehold_rat_traps : public SpellScript
{
    PrepareSpellScript(spell_freehold_rat_traps);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        std::list<Player*> players;
        caster->GetPlayerListInGrid(players, 12.0f);
        for (Player* player : players)
            if (player->IsAlive() && caster->IsWithinDistInMap(player, 8.0f))
                player->CastSpell(player, FreeholdInstanceSpells::SpellRatTrapsRoot, true);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_freehold_rat_traps::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddSC_instance_freehold()
{
    RegisterInstanceScript(instance_free_hold, 1754);
    new npc_free_hold_entrance_teleporter();
    RegisterSpellScript(spell_freehold_rat_traps);
}