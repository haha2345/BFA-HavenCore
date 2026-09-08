-- 837 blizzlike: 神圣化身/纳鲁/治疗之环/光之尾迹/宇宙涟漪/圣光涌动/祈福。
-- 禁止 INSERT 77485/123262/88685/120517/110744/208065/196358/109175 空壳。
-- 禁止 DELETE 2060/2061/596/33076/139/32546/2050/34861/88625/64844/47788/132157/265202。
DELETE FROM `spell_script_names` WHERE `spell_id` = 200183 AND `ScriptName` = 'spell_pri_apotheosis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (200183, 'spell_pri_apotheosis');

DELETE FROM `spell_script_names` WHERE `spell_id` = 196985 AND `ScriptName` = 'spell_pri_light_of_the_naaru';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (196985, 'spell_pri_light_of_the_naaru');

DELETE FROM `spell_script_names` WHERE `spell_id` = 204883 AND `ScriptName` = 'spell_pri_circle_of_healing';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (204883, 'spell_pri_circle_of_healing');

DELETE FROM `spell_script_names` WHERE `spell_id` = 200128 AND `ScriptName` = 'spell_pri_trail_of_light';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (200128, 'spell_pri_trail_of_light');

DELETE FROM `spell_script_names` WHERE `spell_id` = 238136 AND `ScriptName` = 'spell_pri_cosmic_ripple';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (238136, 'spell_pri_cosmic_ripple');

DELETE FROM `spell_script_names` WHERE `spell_id` = 109186 AND `ScriptName` = 'spell_pri_surge_of_light';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (109186, 'spell_pri_surge_of_light');

DELETE FROM `spell_script_names` WHERE `spell_id` = 193157 AND `ScriptName` = 'spell_pri_benediction';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (193157, 'spell_pri_benediction');
