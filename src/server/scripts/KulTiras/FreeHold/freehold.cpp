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

#include "Creature.h"
#include "Player.h"
#include "ScriptedGossip.h"
#include "ScriptMgr.h"
#include "World.h"
#include "freehold.h"

enum FreeHoldTrashSpells
{
    ///Irontide Enforcer 129602 — SAI casts 257426. 257246 is Reincarnation in 35662.
    BrutalBackhand = 257426,
    ShateringToss = 274860,
    ///Irontide Mastiff
    CripplingBite = 257478,
    BestialWrath = 257476,
    ///Irontide Corsair
    PoisoningStrike = 257436,
    ///Irontide Crackshot
    AzeriteGranade = 258672,
    ///Irontide Bonesaw
    FilthyBlade = 258321,
    InfectedWound = 258323,
    HealingBalm = 257397,
    ///Blacktooth Brute
    EarthShaker = 257747,
    ///Cutwater Duelist
    DuelistDash = 274400,
    ///Irontide Oarsman
    SeaSpout = 258777,
    ///Bilge Rat Padfoot
    PlagueStep = 257775,
    ///Cutwater Knife Juggler
    RicochetingThrow = 272402,
    ///Vermin Trapper 130404 — 274383 is DUMMY; soak/root aura is 274389
    RatTraps = 274383,
    RatTrapsRoot = 274389,
    ///Soggy Shiprat
    ScabrousBite = 274555,
    ///BlacktoothKnuckleduster
    ShatteringBellow = 257732,
    ///Blacktooth Scrapper
    BlindRage = 257739,
    ///Cutwater Harpooner 129601 — SAI casts 272412 (272413 is a different 35662 spell)
    DraggingHarpoon = 272412,
    ///Irontide Crusher
    BoulderThrow = 258181,
    GroundShatter = 258199,
    ///Irontide Officer
    OiledBlade = 257908,
    ///Irontide Ravager
    PainfulMotivation = 257899,
    ///Irontide Stormcaller 126919
    LightningBolt = 259092,
    ThunderingSquall = 257736,
    ///Bilge Rat Brinescale 129600 — dump SAI already casts both
    WaterBolt = 281420,
    FrostBlast = 257784,
    ///Irontide Buccaneers
    BladeBarrage = 257870,
};

void AddSC_freehold()
{

}
