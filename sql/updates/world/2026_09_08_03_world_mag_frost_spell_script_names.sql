-- 837 blizzlike: 冰霜卸军团连锁反应 195419。8.3 号是 278309，冰枪脚本已读，不 INSERT 空壳。
-- 禁止 INSERT 12472/112965/190447/278309/205024/135029/112948/116/84714/190356 空壳。270233 本文件 INSERT spell_mage_freezing_rain。
-- 禁止 DELETE 257537/108839/157997/76613。禁止 INSERT Ice Nova 第二套。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 195419 AND `ScriptName` = 'spell_mage_chain_reaction';

DELETE FROM `spell_script_names` WHERE `spell_id` = 270233 AND `ScriptName` = 'spell_mage_freezing_rain';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (270233, 'spell_mage_freezing_rain');
