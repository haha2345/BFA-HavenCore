-- 837 blizzlike: 酒仙铁骨/幻灭连击/闪转腾挪/金钟罩。卸 PvP 202162。
-- 禁止 INSERT 196737/196721/132578/322507/115307/202162 空壳。
-- 禁止 INSERT 119381/115078。精通 117906 dump 已有行则保留。
DELETE FROM `spell_script_names` WHERE `spell_id` = 115308 AND `ScriptName` = 'spell_monk_ironskin_brew';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (115308, 'spell_monk_ironskin_brew');

DELETE FROM `spell_script_names` WHERE `spell_id` = 196736 AND `ScriptName` = 'spell_monk_blackout_combo';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (196736, 'spell_monk_blackout_combo');

DELETE FROM `spell_script_names` WHERE `spell_id` = 202162 AND `ScriptName` = 'spell_monk_guard';
DELETE FROM `spell_script_names` WHERE `spell_id` = 115295 AND `ScriptName` = 'spell_monk_guard';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (115295, 'spell_monk_guard');
