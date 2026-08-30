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
#include "Creature.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptedGossip.h"
#include "SharedDefines.h"
#include "World.h"
#include "WorldSession.h"

enum MotherChamberGossipAction
{
    GOSSIP_ACTION_MOTHER_PURIFY = GOSSIP_ACTION_INFO_DEF + 1,
    GOSSIP_ACTION_MOTHER_CURIOUS_CORRUPTION = GOSSIP_ACTION_INFO_DEF + 2
};

class npc_mother_chamber_of_heart : public CreatureScript
{
public:
    npc_mother_chamber_of_heart() : CreatureScript("npc_mother_chamber_of_heart") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PrepareQuestMenu(creature->GetGUID());

        // Mode=1 contaminant rows live in mGameEventVendors, not npc_vendor. Core PrepareGossipMenu hides vendor on an empty static list.
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "我想看看你的货物。", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_TRADE);

        QuestStatus curiousStatus = player->GetQuestStatus(QUEST_CURIOUS_CORRUPTION);
        if (curiousStatus == QUEST_STATUS_INCOMPLETE || curiousStatus == QUEST_STATUS_COMPLETE)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "我需要和你谈谈这些腐蚀。", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_MOTHER_CURIOUS_CORRUPTION);

        bool allowPurify = true;
        if (sWorld->getIntConfig(CONFIG_MOTHER_REQUIRE_CURIOUS_CORRUPTION)
            && player->GetQuestStatus(QUEST_CURIOUS_CORRUPTION) != QUEST_STATUS_REWARDED)
            allowPurify = false;

        if (allowPurify)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "我有一个腐蚀物品需要净化。", GOSSIP_SENDER_MAIN, GOSSIP_ACTION_MOTHER_PURIFY);

        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);

        if (action == GOSSIP_ACTION_TRADE)
        {
            player->GetSession()->SendListInventory(creature->GetGUID());
            return true;
        }

        if (action == GOSSIP_ACTION_MOTHER_CURIOUS_CORRUPTION)
        {
            player->KilledMonsterCredit(NPC_CREDIT_WRATHION_INSIGHT);
            player->KilledMonsterCredit(NPC_CREDIT_MOTHER_INSIGHT);
            OnGossipHello(player, creature);
            return true;
        }

        if (action == GOSSIP_ACTION_MOTHER_PURIFY)
        {
            if (sWorld->getIntConfig(CONFIG_MOTHER_REQUIRE_CURIOUS_CORRUPTION)
                && player->GetQuestStatus(QUEST_CURIOUS_CORRUPTION) != QUEST_STATUS_REWARDED)
                return true;

            // SendCloseGossip Reset()s InteractionData; record the purify token after gossip is closed.
            // Client then sends CMSG_CLOSE_INTERACTION with this NPC; HandleCloseInteraction keeps the token.
            CloseGossipMenuFor(player);
            player->GetSession()->SendUiItemInteractionNpc(creature->GetGUID(), UI_ITEM_INTERACTION_TITANIC_PURIFICATION);
            return true;
        }

        return true;
    }
};

void AddSC_npc_mother_chamber_of_heart()
{
    new npc_mother_chamber_of_heart();
}
