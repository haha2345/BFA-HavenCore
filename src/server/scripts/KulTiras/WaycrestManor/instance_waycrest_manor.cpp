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
#include "Player.h"
#include "InstanceScript.h"
#include "waycrest_manor.h"

DoorData const doorData[] =
{
    { GO_HEARTSBANE_TRIAD_DOOR, DATA_HEARTSBANE_TRIAD, DOOR_TYPE_ROOM, BOUNDARY_NONE },
    { DOODAD_SFX_LORD_AND_LADY_WAYCREST, DATA_LORD_AND_LADY_WAYCREST, DOOR_TYPE_PASSAGE, BOUNDARY_NONE },
    { 0, 0, DOOR_TYPE_ROOM, BOUNDARY_NONE },
};

struct instance_waycrest_manor : public InstanceScript
{
    instance_waycrest_manor(InstanceMap* map) : InstanceScript(map)
    {
        SetHeaders(DataHeader);
        SetBossNumber(EncounterCount);
    }

    void Initialize() override { LoadDoorData(doorData); }
};

void AddSC_instance_waycrest_manor()
{
    RegisterInstanceScript(instance_waycrest_manor, 1862);
}
