#include "ScriptMgr.h"
#include "Player.h"
#include "InstanceScript.h"
#include "Map.h"
#include "Conversation.h"
#include "ObjectMgr.h"
#include "Creature.h"
#include "Log.h"
#include "operation_mechagon.h"
#include "squirt_lifecycle.h"

#include <sstream>
#include <string>
#include <vector>

/*DoorData const doorData[] =
{
    { , , DOOR_TYPE_ROOM },
    { , , DOOR_TYPE_ROOM },
    { , , DOOR_TYPE_ROOM },
};*/

struct instance_operation_mechagon : public InstanceScript
{
    instance_operation_mechagon(InstanceMap* map) : InstanceScript(map), _releaseMask(0)
    {
        SetHeaders(DataHeader);
        SetBossNumber(EncounterCount);
    }

    void OnCreatureCreate(Creature* creature) override
    {
        InstanceScript::OnCreatureCreate(creature);

        std::optional<std::uint8_t> const monstrosityBit = MonstrosityBit(creature->GetMapId(), creature->GetEntry(), creature->GetSpawnId());
        if (monstrosityBit.has_value())
            creature->SetFaction(16); // local compatibility so these three can be attacked; local database template faction stays 35; official faction unverified
    }

    uint32 GetData(uint32 type) const override
    {
        if (type == DATA_SQUIRT_RELEASE_MASK)
            return _releaseMask;
        return InstanceScript::GetData(type);
    }

    void SetData(uint32 type, uint32 data) override
    {
        // Mask 3 is legal. ZoneScript::SetData would store last_data when the value is 3.
        if (type == DATA_SQUIRT_RELEASE_MASK)
        {
            if (data <= 7)
                _releaseMask = uint8(data);
            return;
        }
        InstanceScript::SetData(type, data);
    }

    void OnUnitDeath(Unit* unit) override
    {
        if (!unit)
            return;
        if (Player* player = unit->ToPlayer())
        {
            GunkerPlayerGoopPlayerDied(this, player);
            return;
        }
        Creature* creature = unit->ToCreature();
        if (!creature)
            return;

        std::optional<std::uint8_t> const bit = MonstrosityBit(creature->GetMapId(), creature->GetEntry(), creature->GetSpawnId());
        if (!bit.has_value())
            return;

        uint8 const oldMask = _releaseMask;
        uint8 const newMask = uint8(oldMask | (1u << *bit));
        if (newMask == oldMask)
            return;

        SetData(DATA_SQUIRT_RELEASE_MASK, newMask);
        SaveToDB();
        TC_LOG_INFO("scripts", "GunkerRelease map %u entry %u spawn %llu mask %u -> %u",
            creature->GetMapId(), creature->GetEntry(), static_cast<unsigned long long>(creature->GetSpawnId()),
            uint32(oldMask), uint32(newMask));

        std::optional<SquirtReleaseBot> const botRow = SquirtReleaseBotForBit(*bit);
        if (!botRow.has_value() || !instance)
            return;

        std::vector<Creature*> deadBots;
        auto bounds = instance->GetCreatureBySpawnIdStore().equal_range(botRow->spawnId);
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
        {
            Creature* bot = itr->second;
            if (!bot || bot->IsAlive())
                continue;
            if (bot->GetSpawnId() != botRow->spawnId || bot->GetEntry() != botRow->entry)
                continue;
            if (!SquirtIsOwnedStatic(bot->GetMapId(), bot->GetEntry(), bot->GetSpawnId()))
                continue;
            deadBots.push_back(bot);
        }
        for (Creature* bot : deadBots)
            bot->Respawn(false);
    }

    void OnCreatureRemove(Creature* creature) override
    {
        GunkerPlayerGoopCreatureRemoved(this, creature);
        InstanceScript::OnCreatureRemove(creature);
    }

    bool SetBossState(uint32 id, EncounterState state) override
    {
        bool const accepted = InstanceScript::SetBossState(id, state);
        if (!accepted)
            return false;
        if (id == DATA_GUNKER && (state == FAIL || state == NOT_STARTED))
            GunkerPlayerGoopEncounterReset(this);
        return accepted;
    }

    void Update(uint32 diff) override
    {
        InstanceScript::Update(diff);
        GunkerPlayerGoopUpdate(this);
    }

    void ReadSaveDataMore(std::istringstream& data) override
    {
        std::ostringstream gathered;
        if (std::streambuf* buffer = data.rdbuf())
            gathered << buffer;
        SquirtMaskToken const token = ClassifySquirtMaskToken(gathered.str());

        uint32 respawnRestore = 0;
        if (token.kind == SquirtMaskTokenKind::Accepted)
            _releaseMask = token.value;
        else if (token.kind == SquirtMaskTokenKind::Absent)
        {
            uint8 const restored = MaskFromRespawnTimes(
                instance->GetCreatureRespawnTime(SQUIRT_SPAWN_150168),
                instance->GetCreatureRespawnTime(SQUIRT_SPAWN_154744),
                instance->GetCreatureRespawnTime(SQUIRT_SPAWN_154758));
            _releaseMask = restored;
            if (restored != 0)
                SaveToDB();
            respawnRestore = 1;
        }
        else
            _releaseMask = 0;

        TC_LOG_INFO("scripts", "GunkerRelease load map %u mask %u respawnRestore %u",
            instance->GetId(), uint32(_releaseMask), respawnRestore);
    }

    void WriteSaveDataMore(std::ostringstream& data) override
    {
        data << uint32(_releaseMask) << ' ';
    }

    void OnPlayerEnter(Player* player) override
    {        
        Conversation::CreateConversation(CONVERSATION_OPERATION_MECHAGON_INTRO, player, player->GetPosition(), { player->GetGUID() });
    };

    uint8 _releaseMask = 0;
};

class instance_operation_mechagon_map : public InstanceMapScript
{
public:
    instance_operation_mechagon_map() : InstanceMapScript("instance_operation_mechagon", 2097) { }

    InstanceScript* GetInstanceScript(InstanceMap* map) const override
    {
        return new instance_operation_mechagon(map);
    }

    void OnPlayerLeave(InstanceMap* map, Player* player) override
    {
        if (map)
            GunkerPlayerGoopPlayerLeaving(map->GetInstanceScript(), map, player);
    }
};

void AddSC_instance_operation_mechagon()
{
    new instance_operation_mechagon_map();
}
