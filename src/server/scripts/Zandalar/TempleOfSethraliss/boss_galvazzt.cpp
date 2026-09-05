#include "ScriptMgr.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "Player.h"
#include "temple_of_sethraliss.h"

const Position pos = { };

enum Spells
{
    SPELL_CONSUME_CHARGE = 266512,
    SPELL_CAPACITANCE = 266511,
    SPELL_ENERGIZE = 265973,
    //Energy core
    SPELL_ENERGY_CORE_VISUAL = 265977,
    SPELL_SUMMON_ENERGY_CORE = 274006,
    SPELL_ARC = 265986,
    SPELL_GALVANIZE = 266923,
};

enum Events
{
    EVENT_ENERGY_CORE = 1,
    EVENT_CONSUME_CHARGE,
};

static bool IsPlayerBlockingGalvazztArc(Position const& core, Position const& boss, Player const* player)
{
    if (!player)
        return false;

    float const dx = boss.GetPositionX() - core.GetPositionX();
    float const dy = boss.GetPositionY() - core.GetPositionY();
    float const lengthSq = dx * dx + dy * dy;
    if (lengthSq <= 0.0f)
        return false;

    float const t = ((player->GetPositionX() - core.GetPositionX()) * dx +
                     (player->GetPositionY() - core.GetPositionY()) * dy) / lengthSq;
    if (t <= 0.10f || t >= 0.90f)
        return false;

    float const closestX = core.GetPositionX() + t * dx;
    float const closestY = core.GetPositionY() + t * dy;
    float const distX = player->GetPositionX() - closestX;
    float const distY = player->GetPositionY() - closestY;
    if ((distX * distX + distY * distY) > (2.5f * 2.5f))
        return false;

    float const closestZ = core.GetPositionZ() + t * (boss.GetPositionZ() - core.GetPositionZ());
    if (std::fabs(player->GetPositionZ() - closestZ) > 10.0f)
        return false;

    return true;
}

//133389
struct boss_galvazzt : public BossAI
{
    boss_galvazzt(Creature* creature) : BossAI(creature, DATA_GALVAZZT) 
    {
        me->RemoveUnitFlag2(UNIT_FLAG2_REGENERATE_POWER);
    }

private:
    uint8 energyCore;

    void Reset() override
    {
        BossAI::Reset();
        me->SetPowerType(POWER_ALTERNATE_POWER);
        me->SetMaxPower(POWER_ALTERNATE_POWER, 100);
        me->SetPower(POWER_ALTERNATE_POWER, 0);
        me->AddAura(AURA_OVERRIDE_POWER_COLOR_OCEAN);
        this->energyCore = 0;
    }

    void EnterCombat(Unit* /*unit*/) override
    {
        _EnterCombat();
        events.ScheduleEvent(EVENT_ENERGY_CORE, 15s);
    }

    void UpdateAI(uint32 diff) override
    {
        if (me->IsInCombat() && me->GetPower(POWER_ALTERNATE_POWER) >= 100)
        {
            me->SetPower(POWER_ALTERNATE_POWER, 0);
            me->CastSpell(nullptr, SPELL_CONSUME_CHARGE, false);
        }
        BossAI::UpdateAI(diff);
    }

    void ExecuteEvent(uint32 eventId) override
    {
        switch (eventId)
        {
        case EVENT_ENERGY_CORE:
            for (uint8 i = 0; i < 3; i++)
            {                
                me->CastSpell(me->GetRandomNearPosition(20.0f), SPELL_SUMMON_ENERGY_CORE, true);
            }
            events.Repeat(15s, 30s);
            break;
        }
    }

    void EnterEvadeMode(EvadeReason /*why*/) override
    {
        me->DespawnCreaturesInArea(NPC_ENERGY_CORE, 125.0f);
    }

    void JustDied(Unit* /*killer*/) override
    {
        _JustDied();
        me->DespawnCreaturesInArea(NPC_ENERGY_CORE, 125.0f);
        if (auto* GalvazztDoor = me->FindNearestGameObject(GO_GALVAZZT_EXIT, 100.0f))
            GalvazztDoor->SetGoState(GO_STATE_ACTIVE);
    }
};

//135445
struct npc_energy_core : public ScriptedAI
{
    npc_energy_core(Creature* c) : ScriptedAI(c) { }

private: 
    uint32 Timer = 0;

    void Reset() override
    {
        ScriptedAI::Reset();
        me->SetReactState(REACT_PASSIVE);
        me->AddUnitFlag(UnitFlags(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_IMMUNE_TO_NPC));
        me->CastSpell(nullptr, SPELL_ENERGY_CORE_VISUAL, true);
        if (Unit* owner = me->GetOwner())
            me->CastSpell(owner, SPELL_ARC, true);
        else
            me->CastSpell(nullptr, SPELL_ARC, true);
        me->GetOwnerGUID();
    }

    void Initialize()
    {
        Timer = 0;
    }

    void UpdateAI(uint32 diff) override
    {
        if (Timer <= diff)
        {
            if (Unit* owner = me->GetOwner())
            {
                if (owner->IsInCombat())
                {
                    bool anyBlocking = false;
                    Map::PlayerList const& playerList = me->GetMap()->GetPlayers();
                    for (Map::PlayerList::const_iterator itr = playerList.begin(); itr != playerList.end(); ++itr)
                    {
                        Player* player = itr->GetSource();
                        if (!player || !player->IsAlive())
                            continue;
                        if (me->GetExactDist(player) > 100.0f)
                            continue;
                        if (IsPlayerBlockingGalvazztArc(*me, *owner, player))
                        {
                            me->CastSpell(player, SPELL_GALVANIZE, true);
                            anyBlocking = true;
                        }
                    }
                    if (!anyBlocking)
                        owner->CastSpell(owner, SPELL_ENERGIZE, true);
                }
                Timer = 1000;
            }
        }
        else Timer -= diff;
    }
};

void AddSC_boss_galvazzt()
{
    RegisterCreatureAI(boss_galvazzt);
    RegisterCreatureAI(npc_energy_core);
}
