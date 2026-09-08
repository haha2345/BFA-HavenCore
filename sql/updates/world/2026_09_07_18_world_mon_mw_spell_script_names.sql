-- 837 blizzlike: 织雾雷茶/朱鹤治疗198756/升腾源泉/专注雷茶/碧玉疾风196725。卸 MoP 法力茶层数与抚慰 193884。
-- 禁止 INSERT 243435/117907/205406/115294/115867/132120/107428 第二套。
-- 禁止 INSERT 198664 / spell_monk_chi_ji（Effect 28 表已召唤 100868）。
-- 禁止 INSERT 196725 到 spell_monk_rushing_jade_wind（那是 116847）。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 123766 AND `ScriptName` = 'spell_monk_mana_tea_stacks';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 193884 AND `ScriptName` = 'spell_monk_soothing_mist_aura';

-- 复苏 HoT 号是 119611。dump 把 spell_monk_renewing_mist_hot 错绑在施法壳 115151。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 115151 AND `ScriptName` = 'spell_monk_renewing_mist_hot';
DELETE FROM `spell_script_names` WHERE `spell_id` = 119611 AND `ScriptName` = 'spell_monk_renewing_mist_hot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (119611, 'spell_monk_renewing_mist_hot');

DELETE FROM `spell_script_names` WHERE `spell_id` = 116680 AND `ScriptName` = 'spell_monk_thunder_focus_tea';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (116680, 'spell_monk_thunder_focus_tea');

DELETE FROM `spell_script_names` WHERE `spell_id` = 198756 AND `ScriptName` = 'spell_monk_chi_ji_heal';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (198756, 'spell_monk_chi_ji_heal');

DELETE FROM `spell_script_names` WHERE `spell_id` = 274963 AND `ScriptName` = 'spell_monk_upwelling';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (274963, 'spell_monk_upwelling');

DELETE FROM `spell_script_names` WHERE `spell_id` = 196725 AND `ScriptName` = 'spell_monk_rushing_jade_wind_mw';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (196725, 'spell_monk_rushing_jade_wind_mw');
