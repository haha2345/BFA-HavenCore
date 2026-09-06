-- 837 blizzlike: 天启 275699 dump 无脚本行。Dummy 4。亡者大军单只 42651 做 8 只封顶。
-- 全心效忠射手 99541 打 Skulker Shot 212423。禁止改 spell_pet.cpp。
DELETE FROM `spell_script_names` WHERE `spell_id` = 275699 AND `ScriptName` = 'spell_dk_apocalypse';
DELETE FROM `spell_script_names` WHERE `spell_id` = 42651 AND `ScriptName` = 'spell_dk_army_ghoul';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (275699, 'spell_dk_apocalypse'),
    (42651, 'spell_dk_army_ghoul');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 99541 AND `source_type` = 0;
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`,
     `comment`)
VALUES
    (99541, 0, 0, 0, 0, 0, 100, 0, 0, 0, 2000, 2000, 0,
     11, 212423, 0, 0, 0, 0, 0,
     2, 0, 0, 0, 0, 0, 0, 0,
     'Risen Skulker - In Combat - Cast Skulker Shot 212423');
