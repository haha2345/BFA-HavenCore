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

 //Missing scripts

#include "freehold.h"
#include "AreaTrigger.h"
#include "AreaTriggerAI.h"
#include "CellImpl.h"
#include "GameObject.h"
#include "GridNotifiersImpl.h"
#include "InstanceScript.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectDefines.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "TemporarySummon.h"

enum CouncilCaptainSpells
{
    UnderOneBanner = 257821, /// Hostile captains keep this even when one captain is friendly
    BilgeRatBrew = 281357, ///This will get players drunk for 1 minute
    ///Captain Raoul Fight
    BlackoutBarrel = 258338,
    BlackoutBarrelVehicleAura = 258875,
    BarrelSmash = 256589,
    ///Captain Eudora Fight
    PowderShot = 256979,
    Grapeshot = 258381,
    GrapeShotFire = 258352,
    ///Captain Jolly Fight
    CuttingSurgeCast = 267522,
    CuttingSurge = 267523,
    WhirlpoolofBlades = 272397,
    WhirlpoolofBladesMissile = 267533,
    ///Allied Captain Buff
    ChainShot = 272902, /// Casted by Captain Eudora if she is Allied
    TappedKeg = 272884, /// Casted by Captain Raoul if he is Allied
    TappedKegBuff = 272900,
    TradeWindsVigor = 281329, /// Casted by Captain Jolly if he is Allied
    ///Heroic Mode
    /// CLEU IDs from BFA S4 WCL report Dvw9JfgPNaVTMCRx fight 1 + LittleWigs v8.3.
    /// 265086 / 264715 / 265171 are same-name 35662 spells but that log never fired them.
    ConfidenceBoostingFreeholdBrew = 265088, /// Crit brew; aura 265085
    InvigoratingFreeholdBrew = 264608, /// Haste brew; aura 265056
    CausticFreeholdBrew = 265168, /// Bad brew; aura 278467
    ConfidenceBoostingFreeholdBrewAura = 265085,
    InvigoratingFreeholdBrewAura = 265056,
    CausticFreeholdBrewAura = 278467
};

uint32 HeroicSpell[3]{ ConfidenceBoostingFreeholdBrew, InvigoratingFreeholdBrew, CausticFreeholdBrew };

enum CouncilCaptainEvents
{
    ///Raoul Enemy Events
    EventBlackoutBarrel,
    EventBarrelSmash,
    ///Eudora Enemy Events
    EventPowderShot,
    EventGrapeshotJump,
    EventGrapeshotFire,
    ///Jolly Enemy Events
    EventCuttingSurge,
    EventWhirlpoolofBlades,
    ///Allied Buff
    EventAlliedBuff,
    ///Heroic Difficulty
    EventLaunchBrew,
    ///Check Player
    EventCheckPlayers /// wipe: evade if no living players remain in combat
};

enum CouncilCaptainAction
{
    ActionResetRummy,
    ActionStartLaunchBrew
};

enum CouncilCaptainMovementPoint
{
    JumpPoint,
};

enum TextEudora
{
    TalkDeadEudora = 0,
    TalkAggroEudora,
};

enum TextJolly
{
    TalkWhirpoolBlade = 0,
    TalkCuttingSurge,
    TalkDeadJolly,
    TalkAggroJolly,
};

enum TextRaoul
{
    TalkAggroRaoul = 0
};

enum Actions
{
    ACTION_COUNT_DEATHS = 1,
};


///ToDo Script the event with the other 2 boss when become allied, need sniff and info about how they become allied, only did Raoul Allied
///This work like Cache of Madness in Zulgurub a different allied by week, is good did that by GameEvent

Position const CouncilTributePos = { -1784.44f, -684.403f, 38.517f,	3.15363f };

struct npc_captains_controller : public ScriptedAI
{
    npc_captains_controller(Creature* creature) : ScriptedAI(creature)
    {
        Initialize();
        m_Instance = creature->GetInstanceScript();

        SetCombatMovement(false);
    }

    void Initialize()
    {
        summonChest = false;
        captainsDeathCount = 0;
    }

    InstanceScript* m_Instance;

    uint8 captainsDeathCount;
    bool summonChest;

    void InitializeAI() override
    {
        me->AddUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        me->AddUnitFlag(UNIT_FLAG_NOT_ATTACKABLE_1);
        me->AddUnitState(UNIT_STATE_STUNNED);

        ScriptedAI::InitializeAI();
    }

    void Reset() override
    {
        Initialize();
    }
    
     void DoAction(int32 action)
    {
        switch (action)
        {
        case ACTION_COUNT_DEATHS:
            ++captainsDeathCount;
            break;
        }
    }

    void UpdateAI(uint32 /*diff*/) override
    {
        if (instance)
        {
            if (captainsDeathCount >= 2 && instance->GetBossState(FreeholdData::DataCounciloCaptains) != DONE)
            {
                if (!summonChest)
                {
                    Map::PlayerList const& PlayerList = me->GetMap()->GetPlayers();
                    if (!PlayerList.isEmpty())
                    {
                        for (Map::PlayerList::const_iterator i = PlayerList.begin(); i != PlayerList.end(); ++i)
                        {
                            Player* player = i->GetSource();
                            player->SummonGameObject(FreeholdGameObject::GoCouncilTribute, CouncilTributePos, QuaternionData(), 0);
                            summonChest = true;
                            break;
                        }
                    }
                }
                instance->SetBossState(FreeholdData::DataCounciloCaptains, DONE);
            }
        }
    }
};

/// 126845 Captain Jolly, 126848 Captain Eudora, 126847 Captain Raoul
struct boss_council_captain : public BossAI
{
    boss_council_captain(Creature* creature) : BossAI(creature, FreeholdData::DataCounciloCaptains)
    {
        m_Instance = creature->GetInstanceScript();
        reset = false;
    }

    InstanceScript* m_Instance;

    void Reset() override
    {
        reset = false;
        grapershotcount = 0;
        resetFight = true;
        evadeModeActivated = false;
        me->ResetLootMode();
        events.Reset();
        summons.DespawnAll();
        me->RemoveAllAreaTriggers();
        me->AddUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        me->AddUnitFlag(UNIT_FLAG_NOT_ATTACKABLE_1);
        if (instance)
        {
            instance->SetBossState(FreeholdData::DataCounciloCaptains, NOT_STARTED);
        }

        if (Creature* jolly = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainJolly)))
        {
            if (Creature* raoul = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainRaoul)))
            {
                if (Creature* eudora = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainEudora)))
                {
                    if (jolly->isDead())
                    {
                        jolly->Respawn();
                        jolly->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
                        jolly->GetMotionMaster()->MoveTargetedHome();
                    }
                    if (raoul->isDead())
                    {
                        raoul->Respawn();
                        raoul->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
                        raoul->GetMotionMaster()->MoveTargetedHome();
                    }
                    if (eudora->isDead())
                    {
                        eudora->Respawn();
                        eudora->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
                        eudora->GetMotionMaster()->MoveTargetedHome();
                    }
                }
            }
        }

        me->SetReactState(REACT_DEFENSIVE);
        me->SetFaction(FreeHoldFaction::FactionEnemy);
        if (instance && GetEffectiveFriendlyCaptainEntry(instance) == me->GetEntry())
        {
            me->SetFaction(FreeHoldFaction::FactionFriendlyFake);
            me->RemoveAura(CouncilCaptainSpells::UnderOneBanner);
        }

        AddTimedDelayedOperation(3 * TimeConstants::IN_MILLISECONDS, [this]() -> void
            {
                // Always one friendly captain from the weekly rotation. Skipping the rum
                // alley event no longer leaves all three hostile.
                if (instance && GetEffectiveFriendlyCaptainEntry(instance) == me->GetEntry())
                {
                    me->SetFaction(FreeHoldFaction::FactionFriendlyFake);
                    me->RemoveAura(CouncilCaptainSpells::UnderOneBanner);
                }

                checkFaction();
                me->RemoveUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
            });
    }

    void EnterEvadeMode(EvadeReason /*why*/) override
    {
        ///Avoid enter two time here
        if (evadeModeActivated || !reset)
            return;

        evadeModeActivated = true;
        me->AttackStop();
        me->CastStop();
        me->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
        me->InterruptNonMeleeSpells(true);
        me->SetReactState(ReactStates::REACT_PASSIVE);
        me->DeleteThreatList();
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveTargetedHome();

        // Reset the controller
        if (Creature* capControl = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DataCaptainsController)))
            ENSURE_AI(npc_captains_controller, capControl->AI())->Reset();
    }

    void JustReachedHome() override
    {
        _JustReachedHome();
        instance->SetBossState(FreeholdData::DataCounciloCaptains, FAIL);
        Reset();
    }

    void EnterCombat(Unit* /*unit*/) override
    {
        if (instance)
        {
            // bosses do not respawn, check only on enter combat
            if (!instance->CheckRequiredBosses(me->GetEntry()))
            {
                EnterEvadeMode(EVADE_REASON_SEQUENCE_BREAK);
                return;
            }
            instance->SetBossState(FreeholdData::DataCounciloCaptains, IN_PROGRESS);
            instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me, 1);
        }
        me->setActive(true);
        CaptainEnterCombat();
        if (IsFreeholdHeroicPlus(me->GetMap()))
        {
            if (Creature* rummy = me->FindNearestCreature(uint32(FreeholdCreature::NpcRummyMancomb), 80.f))
                rummy->AI()->DoAction(CouncilCaptainAction::ActionStartLaunchBrew);
        }
        reset = true;

        switch (me->GetEntry())
        {
        case FreeholdCreature::NpcCaptainJolly:
        {
            Talk(TextJolly::TalkAggroJolly);
            if (me->getFaction() == FreeHoldFaction::FactionEnemy)
            {
                events.ScheduleEvent(CouncilCaptainEvents::EventCuttingSurge, urand(3000, 5000));
                events.ScheduleEvent(CouncilCaptainEvents::EventWhirlpoolofBlades, 8000);
            }
            else
                events.ScheduleEvent(CouncilCaptainEvents::EventAlliedBuff, 8000);
            break;
        }
        case FreeholdCreature::NpcCaptainEudora:
        {
            Talk(TextEudora::TalkAggroEudora);
            if (me->getFaction() == FreeHoldFaction::FactionEnemy)
            {
                events.ScheduleEvent(CouncilCaptainEvents::EventPowderShot, urand(3000, 5000));
                events.ScheduleEvent(CouncilCaptainEvents::EventGrapeshotJump, 8000);
            }
            else
                events.ScheduleEvent(CouncilCaptainEvents::EventAlliedBuff, 8000);
            break;
        }
        case FreeholdCreature::NpcCaptainRaoul:
        {
            Talk(TextRaoul::TalkAggroRaoul);
            if (me->getFaction() == FreeHoldFaction::FactionEnemy)
            {
                events.ScheduleEvent(CouncilCaptainEvents::EventBlackoutBarrel, urand(3000, 5000));
                events.ScheduleEvent(CouncilCaptainEvents::EventBarrelSmash, 8000);
            }
            else
                events.ScheduleEvent(CouncilCaptainEvents::EventAlliedBuff, 8000);
            break;
        }
        }

        events.ScheduleEvent(CouncilCaptainEvents::EventCheckPlayers, 1000);

        checkFaction();
    }

    void DoAction(int32 const action) override
    {
        bool selected = false;
        switch (action)
        {
        case FreeholdAction::ActionSelectCaptainRaoul:
            selected = me->GetEntry() == uint32(FreeholdCreature::NpcCaptainRaoul);
            break;
        case FreeholdAction::ActionSelectCaptainJolly:
            selected = me->GetEntry() == uint32(FreeholdCreature::NpcCaptainJolly);
            break;
        case FreeholdAction::ActionSelectCaptainEudora:
            selected = me->GetEntry() == uint32(FreeholdCreature::NpcCaptainEudora);
            break;
        default:
            break;
        }

        if (selected)
        {
            me->SetFaction(FreeHoldFaction::FactionFriendlyFake);
            checkFaction();
        }
    }
    
    Creature* GetController()
    {
        if (!instance)
            return nullptr;
        return ObjectAccessor::GetCreature(*me, instance->GetGuidData(DataCaptainsController));
    }

    void JustDied(Unit* /*killer*/) override
    {
        switch (me->GetEntry())
        {
        case FreeholdCreature::NpcCaptainJolly:
        {
            Talk(TextJolly::TalkDeadJolly);
            break;
        }
        case FreeholdCreature::NpcCaptainEudora:
        {
            Talk(TextEudora::TalkDeadEudora);
            break;
        }
        }

        if (me->getFaction() == FreeHoldFaction::FactionFriendlyFake)
            return;

        if (Creature* controller = GetController())
        {
            controller->AI()->DoAction(ACTION_COUNT_DEATHS);
        }
    }

    void MovementInform(uint32 type, uint32 pointId) override
    {
        if (type != EFFECT_MOTION_TYPE) ///Jump Effect
            return;

        switch (pointId)
        {
        case CouncilCaptainMovementPoint::JumpPoint:
        {
            events.ScheduleEvent(CouncilCaptainEvents::EventGrapeshotFire, 500);
            break;
        }
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (instance->GetBossState(FreeholdData::DataSkycapKragg) == DONE)
        {
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_ATTACKABLE_1);
        }

        UpdateOperations(diff);
        if (!UpdateVictim() && me->getFaction() == FreeHoldFaction::FactionEnemy)
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
            case CouncilCaptainEvents::EventBlackoutBarrel:
            {
                if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, NonTankTargetSelector(me)))
                    me->CastSpell(target, CouncilCaptainSpells::BlackoutBarrel, false);

                events.Repeat(8000);
                break;
            }
            case CouncilCaptainEvents::EventBarrelSmash:
            {
                me->CastSpell(me, CouncilCaptainSpells::BarrelSmash, false);

                events.Repeat(8000);
                break;
            }
            case CouncilCaptainEvents::EventPowderShot:
            {
                if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0.0, 0.0, true))
                    me->CastSpell(target, CouncilCaptainSpells::PowderShot, false);

                events.Repeat(8000);
                break;
            }
            case CouncilCaptainEvents::EventGrapeshotJump:
            {
                me->StopMoving();
                me->AttackStop();
                me->CastStop();
                me->SetReactState(REACT_PASSIVE);
                me->GetMotionMaster()->MoveJump(GetRandomPositionAround(), 10.0f, 10.0f, CouncilCaptainMovementPoint::JumpPoint);
                break;
            }
            case CouncilCaptainEvents::EventGrapeshotFire:
            {
                grapershotcount++;
                if (grapershotcount < 6) ///Aprox 5 shoots
                {
                    events.CancelEvent(CouncilCaptainEvents::EventGrapeshotJump);
                    events.CancelEvent(CouncilCaptainEvents::EventPowderShot);
                    if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0.0, 0.0, true))
                    {
                        me->SetFacingToObject(target);
                        me->CastSpell(target, CouncilCaptainSpells::GrapeShotFire, false);
                    }

                    events.Repeat(1500);
                }
                else
                {
                    me->SetReactState(REACT_AGGRESSIVE);
                    grapershotcount = 0;
                    events.ScheduleEvent(CouncilCaptainEvents::EventPowderShot, urand(3000, 5000));
                    events.ScheduleEvent(CouncilCaptainEvents::EventGrapeshotJump, 15000);
                }
                break;
            }
            case CouncilCaptainEvents::EventCuttingSurge:
            {
                Talk(TextJolly::TalkCuttingSurge);
                if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0.0, 0.0, true))
                    me->CastSpell(target, CouncilCaptainSpells::CuttingSurgeCast, false);

                events.Repeat(15000);
                break;
            }
            case CouncilCaptainEvents::EventWhirlpoolofBlades:
            {
                Talk(TextJolly::TalkWhirpoolBlade);
                if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0.0, 0.0, true))
                    me->CastSpell(target, CouncilCaptainSpells::WhirlpoolofBladesMissile, false);

                events.Repeat(15000);
                break;
            }
            case CouncilCaptainEvents::EventCheckPlayers:
            {
                Map::PlayerList const& PlayerList = me->GetMap()->GetPlayers();
                if (!PlayerList.isEmpty())
                {
                    for (Map::PlayerList::const_iterator i = PlayerList.begin(); i != PlayerList.end(); ++i)
                    {
                        Player* player = i->GetSource();
                        if (player->IsAlive() && player->IsInCombat())
                        {
                            resetFight = false;
                            break;
                        }
                        else
                            resetFight = true;
                    }
                }

                if (resetFight)
                    if (Creature* jolly = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainJolly)))
                    {
                        if (Creature* raoul = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainRaoul)))
                        {
                            if (Creature* eudora = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainEudora)))
                            {
                                jolly->AI()->EnterEvadeMode(EVADE_REASON_NO_HOSTILES);
                                raoul->AI()->EnterEvadeMode(EVADE_REASON_NO_HOSTILES);
                                eudora->AI()->EnterEvadeMode(EVADE_REASON_NO_HOSTILES);
                            }
                        }
                    }

                events.Repeat(1000);
                break;
            }
            case CouncilCaptainEvents::EventAlliedBuff:
            {
                switch (me->GetEntry())
                {
                case FreeholdCreature::NpcCaptainJolly:
                {
                    me->CastSpell(me, CouncilCaptainSpells::TradeWindsVigor, false);
                    break;
                }
                case FreeholdCreature::NpcCaptainEudora:
                {
                    if (urand(0, 1) == 1)
                    {
                        if (Creature* raoul = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainRaoul)))
                        {
                            me->CastSpell(raoul, CouncilCaptainSpells::ChainShot, false);
                        }
                    }
                    else if (Creature* jolly = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainJolly)))
                    {
                        me->CastSpell(jolly, CouncilCaptainSpells::ChainShot, false);
                    }
                    break;
                }
                case FreeholdCreature::NpcCaptainRaoul:
                {
                    me->CastSpell(me, CouncilCaptainSpells::TappedKeg, false);
                    break;
                }
                }
                events.Repeat(15000);
                break;
            }
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    bool resetFight;
    bool evadeModeActivated;
    bool reset;
    uint8 grapershotcount;

    void checkFaction()
    {
        auto syncBanner = [](Creature* captain)
        {
            if (!captain)
                return;
            if (captain->getFaction() == FreeHoldFaction::FactionEnemy)
                captain->CastSpell(captain, CouncilCaptainSpells::UnderOneBanner, true);
            else
                captain->RemoveAura(CouncilCaptainSpells::UnderOneBanner);
        };

        if (Creature* jolly = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainJolly)))
        {
            if (Creature* raoul = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainRaoul)))
            {
                if (Creature* eudora = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainEudora)))
                {
                    syncBanner(jolly);
                    syncBanner(raoul);
                    syncBanner(eudora);
                }
            }
        }
    }

    void CaptainEnterCombat()
    {
        if (Creature* jolly = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainJolly)))
        {
            if (Creature* raoul = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainRaoul)))
            {
                if (Creature* eudora = m_Instance->instance->GetCreature(m_Instance->GetGuidData(FreeholdCreature::NpcCaptainEudora)))
                {
                    if (!jolly->IsInCombat())
                        jolly->SetInCombatWithZone();
                    if (!raoul->IsInCombat())
                        raoul->SetInCombatWithZone();
                    if (!eudora->IsInCombat())
                        eudora->SetInCombatWithZone();

                    jolly->SetReactState(REACT_AGGRESSIVE);
                    raoul->SetReactState(REACT_AGGRESSIVE);
                    eudora->SetReactState(REACT_AGGRESSIVE);

                    if (raoul->getFaction() == FreeHoldFaction::FactionFriendlyFake)
                    {
                        if (urand(0, 1) == 1)
                            raoul->AI()->AttackStart(jolly);
                        else
                            raoul->AI()->AttackStart(eudora);
                    }
                    else if (jolly->getFaction() == FreeHoldFaction::FactionFriendlyFake)
                    {
                        if (urand(0, 1) == 1)
                            jolly->AI()->AttackStart(raoul);
                        else
                            jolly->AI()->AttackStart(eudora);
                    }
                    else if (eudora->getFaction() == FreeHoldFaction::FactionFriendlyFake)
                    {
                        if (urand(0, 1) == 1)
                            eudora->AI()->AttackStart(raoul);
                        else
                            eudora->AI()->AttackStart(jolly);
                    }
                }
            }
        }
    }

    Position GetRandomPositionAround()
    {
        // Home-relative hop on the rum bar. 18–20 yards from *current* position
        // compounded off the wooden deck (dump bar ~ -1779, -685, z 40).
        Position const home = me->GetHomePosition();
        float const dist = frand(6.0f, 10.0f);
        double const angle = rand_norm() * 2.0 * M_PI;
        float const x = home.GetPositionX() + dist * float(std::sin(angle));
        float const y = home.GetPositionY() + dist * float(std::cos(angle));
        return { x, y, home.GetPositionZ() };
    }
};

/// 133219 - Npc Rummy Mancomb
struct npc_rummy_mancomb : public ScriptedAI
{
    npc_rummy_mancomb(Creature* creature) : ScriptedAI(creature), brewStarted(false) { }

    void Reset()
    {
        me->SetReactState(REACT_PASSIVE);
        me->AddUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        brewStarted = false;
        events.Reset();
    }

    void DoAction(int32 const action) override
    {
        switch (action)
        {
        case CouncilCaptainAction::ActionStartLaunchBrew:
        {
            if (brewStarted)
                break;
            brewStarted = true;
            events.ScheduleEvent(CouncilCaptainEvents::EventLaunchBrew, 8000);
            break;
        }
        case CouncilCaptainAction::ActionResetRummy:
        {
            me->SetReactState(REACT_PASSIVE);
            me->AddUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            brewStarted = false;
            events.Reset();
            me->DeleteThreatList();
            break;
        }
        }
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
            case CouncilCaptainEvents::EventLaunchBrew:
            {
                events.Repeat(5000);

                std::list<Unit*> soakList;
                if (Map* map = me->GetMap())
                {
                    Map::PlayerList const& players = map->GetPlayers();
                    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                    {
                        Player* player = itr->GetSource();
                        if (player && player->IsAlive() && me->IsWithinDistInMap(player, 50.0f))
                            soakList.push_back(player);
                    }
                }

                uint32 const captains[] =
                {
                    uint32(FreeholdCreature::NpcCaptainJolly),
                    uint32(FreeholdCreature::NpcCaptainRaoul),
                    uint32(FreeholdCreature::NpcCaptainEudora)
                };
                for (uint32 entry : captains)
                    if (Creature* captain = me->FindNearestCreature(entry, 50.0f))
                        if (captain->IsAlive())
                            soakList.push_back(captain);

                if (soakList.empty())
                    break;

                if (Unit* target = Trinity::Containers::SelectRandomContainerElement(soakList))
                    me->CastSpell(target, HeroicSpell[urand(0, 2)], true);
                break;
            }
            }
        }
    }

private:
    bool brewStarted;
};

/// 130896 - Blackout Barrel
struct npc_blackout_barrel : public ScriptedAI
{
    npc_blackout_barrel(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(Unit* /*summoner*/) override
    {
        me->SetReactState(REACT_PASSIVE);
        AddTimedDelayedOperation(1 * TimeConstants::IN_MILLISECONDS, [this]() -> void
            {
                me->CastSpell(me, CouncilCaptainSpells::BlackoutBarrelVehicleAura, true);
            });
    }

    void UpdateAI(uint32 const diff) override
    {
        UpdateOperations(diff);
    }
};

///258875 Blackout Barrel
class spell_blackout_vehicle : public SpellScript
{
    PrepareSpellScript(spell_blackout_vehicle);


    void FilterTargetsNoTanks(std::list<WorldObject*>& unitList)
    {
        unitList.remove_if([](WorldObject* object) -> bool
            {
                if (!object->ToPlayer())
                    return true;

                if (object->ToPlayer()->GetRoleForGroup() == Roles::ROLE_TANK)
                    return true;

                return false;
            });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_blackout_vehicle::FilterTargetsNoTanks, EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_blackout_vehicle::FilterTargetsNoTanks, EFFECT_1, TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_blackout_vehicle::FilterTargetsNoTanks, EFFECT_2, TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_blackout_vehicle::FilterTargetsNoTanks, EFFECT_3, TARGET_UNIT_SRC_AREA_ENEMY);
    }
};

///281329 Trade Wind's Vigor
class spell_trade_winds_vigor : public SpellScript
{
    PrepareSpellScript(spell_trade_winds_vigor);


    void FilterTargets(std::list<WorldObject*>& unitList)
    {
        unitList.remove_if([](WorldObject* object) -> bool
            {
                if (!object->ToPlayer())
                    return true;

                return false;
            });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_trade_winds_vigor::FilterTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_ENTRY);
    }
};

class spell_freehold_rummy_brew : public SpellScript
{
    PrepareSpellScript(spell_freehold_rummy_brew);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        SpellInfo const* info = GetSpellInfo();
        if (!caster || !info)
            return;

        uint32 auraId = 0;
        switch (info->Id)
        {
        case CouncilCaptainSpells::ConfidenceBoostingFreeholdBrew:
            auraId = CouncilCaptainSpells::ConfidenceBoostingFreeholdBrewAura;
            break;
        case CouncilCaptainSpells::InvigoratingFreeholdBrew:
            auraId = CouncilCaptainSpells::InvigoratingFreeholdBrewAura;
            break;
        case CouncilCaptainSpells::CausticFreeholdBrew:
            auraId = CouncilCaptainSpells::CausticFreeholdBrewAura;
            break;
        default:
            return;
        }

        Position dest = caster->GetPosition();
        if (Unit* target = GetExplTargetUnit())
            dest.Relocate(*target);
        else if (WorldLocation const* expl = GetExplTargetDest())
            dest.Relocate(*expl);

        std::list<Player*> players;
        caster->GetPlayerListInGrid(players, 80.0f);
        for (Player* player : players)
            if (player->IsAlive() && player->GetExactDist(&dest) <= 6.0f)
                player->CastSpell(player, auraId, true);

        uint32 const captains[] =
        {
            uint32(FreeholdCreature::NpcCaptainJolly),
            uint32(FreeholdCreature::NpcCaptainRaoul),
            uint32(FreeholdCreature::NpcCaptainEudora)
        };
        for (uint32 entry : captains)
            if (Creature* captain = caster->FindNearestCreature(entry, 80.0f))
                if (captain->IsAlive() && captain->GetExactDist(&dest) <= 6.0f)
                    captain->CastSpell(captain, auraId, true);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_freehold_rummy_brew::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

///Spell 272884 Vile Bombardment Areatriger ID 13674
struct at_tapped_keg : AreaTriggerAI
{
    at_tapped_keg(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    void OnUnitEnter(Unit* unit)
    {
        if (Player* player = unit->ToPlayer())
            if (!player->HasAura(CouncilCaptainSpells::TappedKegBuff))
                player->CastSpell(player, CouncilCaptainSpells::TappedKegBuff, true);
    }

    void OnUnitExit(Unit* unit)
    {
        unit->RemoveAurasDueToSpell(CouncilCaptainSpells::TappedKegBuff);
    }
};

///Spell 272377  Whirlpool of Blades Areatriger ID 13632
struct at_whirlpool_of_blades : AreaTriggerAI
{
    at_whirlpool_of_blades(AreaTrigger* areatrigger) : AreaTriggerAI(areatrigger) { }

    void OnInitialize() override
    {
        at->SetPeriodicProcTimer(1000);
    }

    void OnPeriodicProc() override
    {
        if (Unit* caster = at->GetCaster())
        {
            GuidUnorderedSet const& insideUnits = at->GetInsideUnits();

            for (ObjectGuid guid : insideUnits)
                if (Player* player = ObjectAccessor::GetPlayer(*caster, guid))
                    player->CastSpell(player, CouncilCaptainSpells::WhirlpoolofBlades, true);
        }
    }
};

/// 129547 event bodies only (creature.ScriptName on guid 280003428 / 280003429). Do not bind dump's eight regular knuckledusters.
struct npc_freehold_crew_knuckleduster : public ScriptedAI
{
    npc_freehold_crew_knuckleduster(Creature* creature) : ScriptedAI(creature) { }

    void EnterCombat(Unit* /*who*/) override
    {
        for (uint8 i = 0; i < 4; ++i)
            me->SummonCreature(uint32(FreeholdCreature::NpcBlacktoothKnuckleduster), me->GetRandomNearPosition(5.0f), TEMPSUMMON_CORPSE_DESPAWN);
    }

    void JustDied(Unit* /*killer*/) override
    {
        if (GetActiveFreeholdCrewWeek(me->GetInstanceScript()) != CrewWeekBlacktooth)
            return;

        std::list<Creature*> others;
        me->GetCreatureListWithEntryInGrid(others, uint32(FreeholdCreature::NpcBlacktoothKnuckleduster), 200.0f);
        for (Creature* creature : others)
        {
            if (!creature || creature == me || !creature->IsAlive())
                continue;
            if (creature->GetScriptName() == "npc_freehold_crew_knuckleduster")
                return;
        }

        NotifyCrewEventComplete(me->GetInstanceScript(), uint32(FreeholdCreature::NpcCaptainRaoul));
    }
};

/// 130467 Murphy. Simplified gossip: no sniff pathing. Completing the Cutwater week is Otis, not Murphy.
struct npc_freehold_murphy : public ScriptedAI
{
    npc_freehold_murphy(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->AddNpcFlag(UNIT_NPC_FLAG_GOSSIP);
        me->SetReactState(REACT_PASSIVE);
    }

    void sGossipHello(Player* player) override
    {
        if (!player)
            return;
        if (GetActiveFreeholdCrewWeek(me->GetInstanceScript()) != CrewWeekCutwater)
        {
            CloseGossipMenuFor(player);
            return;
        }
        CloseGossipMenuFor(player);
    }
};

/// 129441 Otis (Imprisoned Corsair). Never 12944.
struct npc_freehold_otis : public ScriptedAI
{
    npc_freehold_otis(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->AddNpcFlag(UNIT_NPC_FLAG_GOSSIP);
        me->SetReactState(REACT_PASSIVE);
    }

    void sGossipHello(Player* player) override
    {
        if (!player)
            return;
        if (GetActiveFreeholdCrewWeek(me->GetInstanceScript()) != CrewWeekCutwater)
        {
            CloseGossipMenuFor(player);
            return;
        }
        CloseGossipMenuFor(player);
        NotifyCrewEventComplete(me->GetInstanceScript(), uint32(FreeholdCreature::NpcCaptainJolly));
    }
};

/// Weekly brew NPC. Entry is not pinned; struct + Register must exist anyway.
struct npc_freehold_crew_brew : public ScriptedAI
{
    npc_freehold_crew_brew(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->AddNpcFlag(UNIT_NPC_FLAG_GOSSIP);
        me->SetReactState(REACT_PASSIVE);
    }

    void sGossipHello(Player* player) override
    {
        if (!player)
            return;
        if (GetActiveFreeholdCrewWeek(me->GetInstanceScript()) != CrewWeekBilgeRats)
        {
            CloseGossipMenuFor(player);
            return;
        }

        me->CastSpell(player, CouncilCaptainSpells::BilgeRatBrew, true);
        CloseGossipMenuFor(player);

        Map* map = me->GetMap();
        if (!map)
            return;

        Map::PlayerList const& players = map->GetPlayers();
        if (players.isEmpty())
            return;

        for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
        {
            Player* member = itr->GetSource();
            if (!member || !member->IsAlive())
                continue;
            if (!member->HasAura(CouncilCaptainSpells::BilgeRatBrew))
                return;
        }

        NotifyCrewEventComplete(me->GetInstanceScript(), uint32(FreeholdCreature::NpcCaptainEudora));
    }
};

void AddSC_boss_council_o_captains()
{
    RegisterCreatureAI(boss_council_captain);
    RegisterCreatureAI(npc_rummy_mancomb);
    RegisterCreatureAI(npc_blackout_barrel);
    RegisterCreatureAI(npc_captains_controller);
    RegisterCreatureAI(npc_freehold_crew_knuckleduster);
    RegisterCreatureAI(npc_freehold_murphy);
    RegisterCreatureAI(npc_freehold_otis);
    RegisterCreatureAI(npc_freehold_crew_brew);
    ///Spell
    RegisterSpellScript(spell_blackout_vehicle);
    RegisterSpellScript(spell_trade_winds_vigor);
    RegisterSpellScript(spell_freehold_rummy_brew);
    ///Areatrigger
    RegisterAreaTriggerAI(at_tapped_keg);
    RegisterAreaTriggerAI(at_whirlpool_of_blades);
}
