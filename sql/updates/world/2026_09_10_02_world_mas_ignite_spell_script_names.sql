-- 837 blizzlike: MAS 点燃。凤凰 257541 / 流星伤 153564 必须绑 spell_mastery_ignite。
-- Dummy 75 在 12846 EFFECT_1。BonusCoef 0.75 不是 Dummy。8 码 / 78 级观察窗口不得进 Dummy 75。
-- BFA 公开句：凤凰/流星贡献点燃，不是 9.0 凤凰负责蔓延。
-- 禁止 DELETE (257541, spell_mage_phoenix_flames)。禁止改 spell_mage.cpp 当搬家。
-- 禁止 INSERT 194466/115636/168534/76806/77485/271534/117907/183997/77495/203747/77513。
-- 禁止 DELETE 133/11366/108853/2948/2120/12846/76613/148022/77220/76856/117906/77535。
DELETE FROM `spell_script_names` WHERE `spell_id` = 257541 AND `ScriptName` = 'spell_mastery_ignite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (257541, 'spell_mastery_ignite');
DELETE FROM `spell_script_names` WHERE `spell_id` = 153564 AND `ScriptName` = 'spell_mastery_ignite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (153564, 'spell_mastery_ignite');
