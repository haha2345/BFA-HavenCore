-- 837 blizzlike: 踏风幻灭踢/神鹤乱舞/屏气/真气击打/碧玉疾风/疾风乱打/内力/灵魂聚焦点。
-- 禁止 INSERT 115636/205320/286585/115098 第二套/107428 第二套。
-- 禁止 INSERT 116847 到织雾 196725 名。
DELETE FROM `spell_script_names` WHERE `spell_id` = 100784 AND `ScriptName` = 'spell_monk_blackout_kick';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (100784, 'spell_monk_blackout_kick');

DELETE FROM `spell_script_names` WHERE `spell_id` = 101546 AND `ScriptName` = 'spell_monk_spinning_crane_kick';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (101546, 'spell_monk_spinning_crane_kick');

DELETE FROM `spell_script_names` WHERE `spell_id` = 152173 AND `ScriptName` = 'spell_monk_serenity';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (152173, 'spell_monk_serenity');

DELETE FROM `spell_script_names` WHERE `spell_id` = 261947 AND `ScriptName` = 'spell_monk_fist_of_the_white_tiger';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (261947, 'spell_monk_fist_of_the_white_tiger');

DELETE FROM `spell_script_names` WHERE `spell_id` = 116847 AND `ScriptName` = 'spell_monk_rushing_jade_wind';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (116847, 'spell_monk_rushing_jade_wind');

DELETE FROM `spell_script_names` WHERE `spell_id` = 196740 AND `ScriptName` = 'spell_monk_hit_combo';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (196740, 'spell_monk_hit_combo');

DELETE FROM `spell_script_names` WHERE `spell_id` = 261767 AND `ScriptName` = 'spell_monk_inner_strength';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (261767, 'spell_monk_inner_strength');

DELETE FROM `spell_script_names` WHERE `spell_id` = 280197 AND `ScriptName` = 'spell_monk_spiritual_focus';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (280197, 'spell_monk_spiritual_focus');
