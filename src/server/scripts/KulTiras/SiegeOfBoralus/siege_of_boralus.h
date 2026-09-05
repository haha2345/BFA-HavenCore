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

#ifndef SIEGEOFBORALUS_H
#define SIEGEOFBORALUS_H

#include "DBCEnums.h"
#include "Map.h"

#define DataHeader "SOB"

uint32 const EncounterCount = 5;

enum EncounterData
{
	DATA_CHOPPER_REDHOOK = 0,
	DATA_SERGEANT_BAINBRIDGE = 1,
	DATA_DREAD_CAPTAIN_LOCKWOOD = 2,
	DATA_HADAL_DARKFATHOM = 3,
	DATA_VIQGOTH = 4
};

enum CreatureIds
{
	NPC_CHOPPER_REDHOOK = 128650,
    NPC_SERGEANT_BAINBRIDGE = 128649,
	NPC_DREAD_CAPTAIN_LOCKWOOD = 129208,
	NPC_ASHVANE_DECKHAND = 136483,
	NPC_ASHAVANE_CANNONNEER = 136549,
	NPC_UNSTABLE_ORDNACE = 143618,
	NPC_CANNON_BARRAGE = 132019,
	NPC_DREAD_CANNON = 139277,
	NPC_DREAD_CANNON_BUNNY = 500500,
	NPC_HADAL_DARKFATHOM = 128651,
	NPC_VIQGOTH = 128652,
	NPC_DEMOLISHING_TERROR = 137614,
	NPC_GRIPPING_TERROR = 137405,
	NPC_CANNON_VIQ_ENCOUNTER = 137123,
	NPC_JAINA_SOB_ALI_OUTRO_ALI = 142486,
};

enum Gameobjects
{
	GO_TREASURE_RICH_FLOTSAM = 288639,
	GO_CHALLENGERS_CACHE_BORALUS = 288644
};

inline bool IsSiegeOfBoralusHeroicPlus(Map const* map)
{
    if (!map)
        return false;
    Difficulty const d = map->GetDifficultyID();
    return d == DIFFICULTY_HEROIC || d == DIFFICULTY_MYTHIC; // 2 or 23, not 8
}

#endif // SOB
