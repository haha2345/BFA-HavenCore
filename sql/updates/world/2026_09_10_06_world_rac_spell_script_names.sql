-- 837 blizzlike: RAC 种族战斗。有 Dummy 则读表。260364/256893 本表无 Dummy，观察窗口不得写成 Dummy。
-- 121093 纳鲁之赐武僧号必须绑 spell_gen_gift_of_naaru（Dummy 20 同形）。
-- 20589 逃脱大师 Eff=77；265221 火焰之血 Dummy 0 钩子；287712 重击 Dummy 0；
-- 312411 把戏袋 Dummy 1000；312923 战斗分析 Dummy 5/25/10；58984 影遁 Dummy 0 脱战钩子。
-- 禁止 INSERT 26297/20572/33697/33702/20549/20573/20594/69041/255654/291944/255647/256948/312370/312372/206150。
-- 禁止 DELETE 260364/256893/257040/274738/28880/59542/59543/59544/59545/59547/59548/20577/312916/313010/313015。
-- 禁止占用 2026_09_10_02～_05（MAS）与 2026_09_10_00/_01（PET）。
DELETE FROM `spell_script_names` WHERE `spell_id` = 121093 AND `ScriptName` = 'spell_gen_gift_of_naaru';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (121093, 'spell_gen_gift_of_naaru');
DELETE FROM `spell_script_names` WHERE `spell_id` = 20589 AND `ScriptName` = 'spell_gen_escape_artist';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (20589, 'spell_gen_escape_artist');
DELETE FROM `spell_script_names` WHERE `spell_id` = 265221 AND `ScriptName` = 'spell_gen_fireblood';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (265221, 'spell_gen_fireblood');
DELETE FROM `spell_script_names` WHERE `spell_id` = 287712 AND `ScriptName` = 'spell_gen_haymaker';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (287712, 'spell_gen_haymaker');
DELETE FROM `spell_script_names` WHERE `spell_id` = 312411 AND `ScriptName` = 'spell_gen_bag_of_tricks';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (312411, 'spell_gen_bag_of_tricks');
DELETE FROM `spell_script_names` WHERE `spell_id` = 312923 AND `ScriptName` = 'spell_gen_combat_analysis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (312923, 'spell_gen_combat_analysis');
DELETE FROM `spell_script_names` WHERE `spell_id` = 58984 AND `ScriptName` = 'spell_gen_shadowmeld';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (58984, 'spell_gen_shadowmeld');
