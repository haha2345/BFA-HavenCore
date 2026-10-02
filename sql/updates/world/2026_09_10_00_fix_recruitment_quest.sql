-- Fix Recruitment quest partially

DELETE FROM `smart_scripts` WHERE `entryorguid` = 49150 AND (`event_type` IN (19, 20, 21));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES 
(49150, 0, 10, 0, 19, 0, 100, 0, 26800, 0, 0, 0, 0, 12, 49337, 8, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'On Quest 26800 Accept - Summon Darnell vehicle'),
(49150, 0, 11, 0, 20, 0, 100, 0, 26800, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 10, 49337, 100, 0, 0, 0, 0, 0, 'On Quest 26800 Reward - Despawn Darnell'),
(49150, 0, 12, 0, 21, 0, 100, 0, 26800, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 10, 49337, 100, 0, 0, 0, 0, 0, 'On Quest 26800 Abandon - Despawn Darnell');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 49337;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES 
(49337, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 29, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'On Spawn - Follow Invoker');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 49340;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES 
(49340, 0, 0, 1, 73, 0, 100, 0, 0, 0, 0, 0, 0, 33, 49340, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'On SpellClick - Give Kill Credit to Player'),
(49340, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 10, 49337, 20, 0, 0, 0, 0, 0, 'On SpellClick - Corpse enters Darnell vehicle'),
(49340, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'On SpellClick - Corpse Force Despawn after 5s');

UPDATE `creature_template` SET `npcflag` = 16777216 WHERE `entry` = 49340;

-- NOTE: There are still problems with the quest
