-- 837 blizzlike: 黎明之光治疗弹改 225311，卸军团 185984。
-- 复仇十字军 216331、美德道标 200025 缺家。圣光术 82326 复用闪现脚本摘灌注。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 185984 AND `ScriptName` = 'spell_pal_light_of_dawn_trigger';

DELETE FROM `spell_script_names` WHERE `spell_id` = 216331 AND `ScriptName` = 'spell_pal_avenging_crusader';
DELETE FROM `spell_script_names` WHERE `spell_id` = 200025 AND `ScriptName` = 'spell_pal_beacon_of_virtue';
DELETE FROM `spell_script_names` WHERE `spell_id` = 82326 AND `ScriptName` = 'spell_pal_flash_of_light';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (216331, 'spell_pal_avenging_crusader'),
    (200025, 'spell_pal_beacon_of_virtue'),
    (82326, 'spell_pal_flash_of_light');
