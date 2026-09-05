#include "ScriptMgr.h"
#include "Player.h"
#include "InstanceScript.h"
#include "Conversation.h"
#include "ObjectMgr.h"
#include "operation_mechagon.h"

/*DoorData const doorData[] =
{
    { , , DOOR_TYPE_ROOM },
    { , , DOOR_TYPE_ROOM },
    { , , DOOR_TYPE_ROOM },
};*/

struct instance_operation_mechagon : public InstanceScript
{
    instance_operation_mechagon(InstanceMap* map) : InstanceScript(map)
    {
        SetHeaders(DataHeader);
        SetBossNumber(EncounterCount);
    }

    void OnPlayerEnter(Player* player) override
    {        
        Conversation::CreateConversation(CONVERSATION_OPERATION_MECHAGON_INTRO, player, player->GetPosition(), { player->GetGUID() });
    };
};

void AddSC_instance_operation_mechagon()
{
    RegisterInstanceScript(instance_operation_mechagon, 2097);
}