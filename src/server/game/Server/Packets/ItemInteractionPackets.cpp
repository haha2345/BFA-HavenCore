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

#include "ItemInteractionPackets.h"

WorldPacket const* WorldPackets::ItemInteraction::UiItemInteractionNpc::Write()
{
    _worldPacket << Npc;
    _worldPacket << int32(InteractionID);

    return &_worldPacket;
}

void WorldPackets::ItemInteraction::PerformItemInteraction::Read()
{
    // 8.3 Lua PerformItemInteraction() has no args; pending item lives on the client until this opcode.
    // No 8.3.7 sniff: read up to two GUIDs. HandlePerformItemInteraction resolves item vs NPC by type.
    if (_worldPacket.size() - _worldPacket.rpos() >= 16)
        _worldPacket >> Item;
    if (_worldPacket.size() - _worldPacket.rpos() >= 16)
        _worldPacket >> Npc;
    _worldPacket.rfinish();
}
