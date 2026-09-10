-- 837 blizzlike: AZ 签名。地震波 Dummy 10 是线宽，不是 9.52。浓缩火焰学会 295373，Dummy 100。
-- 278495 Dummy 0 隐藏 proc（Aura 285 核心已挂，脚本不要再 Cast 278495）。
-- 278497 Dummy 0 伤钩子；10.0 码是半径列 Rad1=13。
-- 295373 Dummy 100/100；Coef 16.71 不是 Dummy；30 秒是 Category 1852 不是 Dummy。
-- 295376 Dummy 100 导弹落地。禁止 INSERT 277253/277639/299349/191837/295377/295368/295379/295374/295375/278506。
-- 禁止 DELETE 277253 spell_item_heart_of_azeroth。禁止 DELETE 191837 spell_monk_essence_font。
-- 禁止占用 2026_09_10_06～_08（RAC）、_02～_05（MAS）、_00/_01（PET）。
DELETE FROM `spell_script_names` WHERE `spell_id` = 278495 AND `ScriptName` = 'spell_azerite_seismic_wave_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (278495, 'spell_azerite_seismic_wave_proc');
DELETE FROM `spell_script_names` WHERE `spell_id` = 278497 AND `ScriptName` = 'spell_azerite_seismic_wave_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (278497, 'spell_azerite_seismic_wave_damage');
DELETE FROM `spell_script_names` WHERE `spell_id` = 295373 AND `ScriptName` = 'spell_azerite_concentrated_flame';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (295373, 'spell_azerite_concentrated_flame');
DELETE FROM `spell_script_names` WHERE `spell_id` = 295376 AND `ScriptName` = 'spell_azerite_concentrated_flame_missile';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (295376, 'spell_azerite_concentrated_flame_missile');
