#include "ScriptMgr.h"
#include "Player.h"
#include "InstanceScript.h"
#include "temple_of_sethraliss.h"
#include "GameObject.h"
#include "Creature.h"

DoorData const doorData[] =
{
    { 292551, DATA_ADDERIS_AND_ASPIX, DOOR_TYPE_ROOM , BOUNDARY_NONE },
    { 290906, DATA_MEREKTHA, DOOR_TYPE_ROOM , BOUNDARY_NONE },
    { 292414, DATA_GALVAZZT, DOOR_TYPE_ROOM , BOUNDARY_NONE },
    { 0, 0, DOOR_TYPE_ROOM, BOUNDARY_NONE },
};

struct instance_temple_of_sethraliss : public InstanceScript
{
    instance_temple_of_sethraliss(InstanceMap* map) : InstanceScript(map)
    {
        SetHeaders(DataHeader);
        SetBossNumber(EncounterCount);
    }

    void Initialize() override
    {
        LoadDoorData(doorData);
    }

    void OnGameObjectCreate(GameObject* go) override
    {
        InstanceScript::OnGameObjectCreate(go);
        if (go->GetEntry() == GO_SETHRALISS_TREASURE)
        {
            SethralissTreasureGuid = go->GetGUID();
            UpdateSethralissTreasureLock();
        }
    }

    bool SetBossState(uint32 id, EncounterState state) override
    {
        bool changed = InstanceScript::SetBossState(id, state);
        if (id == DATA_AVATAR_OF_SETHRALISS)
            UpdateSethralissTreasureLock();
        return changed;
    }

    void OnUnitDeath(Unit* unit) override
    {
        if (unit->GetEntry() != NPC_HEART_GUARDIAN)
            return;
        if (GetBossState(DATA_AVATAR_OF_SETHRALISS) != IN_PROGRESS)
            return;
        Creature* avatar = unit->ToCreature() ? unit->FindNearestCreature(NPC_AVATAR_OF_SETHRALISS, 150.f, true) : nullptr;
        if (avatar)
            avatar->CastSpell(*unit, SPELL_ENERGY_FRAGMENT, true);
    }

private:
    ObjectGuid SethralissTreasureGuid;

    void UpdateSethralissTreasureLock()
    {
        GameObject* treasure = instance->GetGameObject(SethralissTreasureGuid);
        if (!treasure)
            return;

        if (GetBossState(DATA_AVATAR_OF_SETHRALISS) == IN_PROGRESS)
            treasure->AddFlag(GO_FLAG_LOCKED);
        else
            treasure->RemoveFlag(GO_FLAG_LOCKED);
    }
};

void AddSC_instance_temple_of_sethraliss()
{
    RegisterInstanceScript(instance_temple_of_sethraliss, 1877);
}
