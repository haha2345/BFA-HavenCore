-- Fix Issue#496: 

-- 1. Remove permanent spawns for Fire Elemental Remnant (34368) and Fire Elemental Rager (34370).
-- They are supposed to be dynamically summoned by the invisible triggers (24042) during the ritual.
DELETE FROM `creature` WHERE `id` IN (34368, 34370);

-- 2. Update the objective description so it says "Ritual of Soothing completed" instead of defaulting to the hidden credit NPC name.
UPDATE `quest_objectives` SET `Description` = 'Ritual of Soothing completed' WHERE `QuestID` = 13580 AND `ObjectID` = 34371;

-- 3. Add the missing start and end RP text for the Energized Soothing Totem (34367).
DELETE FROM `creature_text` WHERE `CreatureID` = 34367;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(34367, 0, 0, 'The ritual of soothing has begun. Defend the totem at all costs!', 41, 0, 100, 0, 0, 0, 0, 0, 'Start ritual'),
(34367, 1, 0, 'The ritual of soothing has completed.', 41, 0, 100, 0, 0, 0, 0, 0, 'End ritual');

-- 4. Make the Totem despawn at the end of the ritual (target_type was incorrectly 0 (None), preventing despawn)
UPDATE `smart_scripts` SET `target_type` = 1 WHERE `entryorguid` = 3436700 AND `id` = 7;

-- 5. Force the Totem to stay completely passive and immobile so it doesn't try to defend the player using Guardian AI.
-- Bake Pacified and Movement Disabled flags directly into the creature_template
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 131076 WHERE `entry` = 34367;

-- Force its ReactState to Passive via SmartAI immediately on spawn
-- Link existing text event (id 1) to our new Passive state event (id 2)
UPDATE `smart_scripts` SET `link` = 2 WHERE `entryorguid` = 34367 AND `id` = 1;

-- Add Set ReactState Passive (id 2) and Set Root (id 3)
DELETE FROM `smart_scripts` WHERE `entryorguid` = 34367 AND `id` IN (2, 3);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param_string`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES 
(34367, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, '', 11, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Link - Passive'),
(34367, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, '', 103, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Link - Set Root');

-- Also clean up the intermediate script from earlier fixes just in case
DELETE FROM `smart_scripts` WHERE `entryorguid` = 3436700 AND `id` IN (10, 11);
