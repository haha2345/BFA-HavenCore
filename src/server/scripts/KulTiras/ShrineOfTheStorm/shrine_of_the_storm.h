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

#ifndef SHRINE_OF_THE_STORM_H
#define SHRINE_OF_THE_STORM_H

#include "DBCEnums.h"
#include "Map.h"

#define DataHeader "SOTS"

uint32 const EncounterCount = 4;

enum EncounterData
{
    DATA_AQUSIRR            = 0,
    DATA_TIDESAGE_COUNCIL   = 1,
    DATA_LORD_STORMSONG     = 2,
    DATA_VOLZITH            = 3,
    DATA_INSTANCE_ENTER     = 4,
    DATA_AQUALING           = 5,
};

enum CreatureIds
{
    NPC_AQUSIRR                 = 134056,
    NPC_BROTHER_IRONHULL        = 134063,
    NPC_GALECALLER_FAYE         = 134058,
    NPC_LORD_STORMSONG          = 139737, // 序章体，家在 shrine_of_the_storm.cpp；第三王战斗体是 boss 文件里的 134060
    NPC_VOLZITH_THE_WHISPERER   = 134069,
    NPC_REXXAR                  = 139971,
    NPC_BROTHER_PIKE            = 139970,
    NPC_ANCIENT_MINDBENDER      = 137051,
    NPC_AWOKEN_VOID             = 137036,
};

inline bool IsShrineHeroicPlus(Map const* map)
{
    if (!map)
        return false;
    Difficulty const d = map->GetDifficultyID();
    return d == DIFFICULTY_HEROIC || d == DIFFICULTY_MYTHIC; // 2 or 23, not 8
}

#endif // SHRINE_OF_THE_STORM_H
