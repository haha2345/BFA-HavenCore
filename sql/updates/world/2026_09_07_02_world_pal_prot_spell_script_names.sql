-- 837 blizzlike: 132403 是护甲 Aura 268，需要独立 AuraScript 旁路。
-- 85043 大十字军被动缺 Aura 家（锤 AfterCast 不再掷骰；几率不进 C++）。
-- 203791 最后的防御者缺家。
DELETE FROM `spell_script_names` WHERE `spell_id` = 132403 AND `ScriptName` = 'spell_pal_shield_of_the_righteous_armor';
DELETE FROM `spell_script_names` WHERE `spell_id` = 85043 AND `ScriptName` = 'spell_pal_grand_crusader_aura';
DELETE FROM `spell_script_names` WHERE `spell_id` = 203791 AND `ScriptName` = 'spell_pal_last_defender';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (132403, 'spell_pal_shield_of_the_righteous_armor'),
    (85043, 'spell_pal_grand_crusader_aura'),
    (203791, 'spell_pal_last_defender');
