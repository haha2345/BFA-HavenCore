-- 837 blizzlike: 生存猫鼬 259387；野火 259495 与三色玩家号；杀敌 259489；侧翼 269751。
-- 卸军团 190928 / 经典 1978 / 军团 202800。不要 INSERT 266779 / 259491 / 271014 空类。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 190928 AND `ScriptName` = 'spell_hun_mongoose_bite';
DELETE FROM `spell_script_names` WHERE `spell_id` = 259387 AND `ScriptName` = 'spell_hun_mongoose_bite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (259387, 'spell_hun_mongoose_bite');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (259495, 270335, 271045, 270323) AND `ScriptName` = 'spell_hun_wildfire_bomb';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (259495, 'spell_hun_wildfire_bomb'),
    (270335, 'spell_hun_wildfire_bomb'),
    (271045, 'spell_hun_wildfire_bomb'),
    (270323, 'spell_hun_wildfire_bomb');

DELETE FROM `spell_script_names` WHERE `spell_id` = 259489 AND `ScriptName` = 'spell_hun_kill_command_survival';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (259489, 'spell_hun_kill_command_survival');

DELETE FROM `spell_script_names` WHERE `spell_id` = 259277 AND `ScriptName` = 'spell_hun_kill_command_sv_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (259277, 'spell_hun_kill_command_sv_damage');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 1978 AND `ScriptName` = 'spell_hun_serpent_sting';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 202800 AND `ScriptName` = 'spell_hun_flanking_strike';
DELETE FROM `spell_script_names` WHERE `spell_id` = 269751 AND `ScriptName` = 'spell_hun_flanking_strike';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (269751, 'spell_hun_flanking_strike');

DELETE FROM `spell_script_names` WHERE `spell_id` = 212436 AND `ScriptName` = 'spell_hun_carve';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (212436, 'spell_hun_carve');
