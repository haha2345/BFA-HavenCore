-- 837 blizzlike: 毁灭者 236279 缺脚本。Dummy 20 / Trigger 236282 按 35662 读。
DELETE FROM `spell_script_names` WHERE `spell_id` = 236279 AND `ScriptName` = 'spell_warr_devastator';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (236279, 'spell_warr_devastator');
