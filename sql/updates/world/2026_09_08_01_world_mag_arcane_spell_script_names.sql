-- 837 blizzlike: 奥术强化隐形/触碰/虚空风暴/时间异常/节制。
-- 禁止 INSERT 12042/12051/155147/205032/190740/264354/205028/281482/321507/210134/224968/153626/205022 空壳（魔宠绑 210126）。
-- 禁止 INSERT 157980 第二套（已有 spell_mage_nova_talent）。禁止 INSERT 110959 到 MAG-C 空名。
DELETE FROM `spell_script_names` WHERE `spell_id` = 110959 AND `ScriptName` = 'spell_mage_greater_invisibility';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (110959, 'spell_mage_greater_invisibility');

DELETE FROM `spell_script_names` WHERE `spell_id` = 110960 AND `ScriptName` = 'spell_mage_greater_invisibility_buff';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (110960, 'spell_mage_greater_invisibility_buff');

DELETE FROM `spell_script_names` WHERE `spell_id` = 210725 AND `ScriptName` = 'spell_mage_touch_of_the_magi';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (210725, 'spell_mage_touch_of_the_magi');

DELETE FROM `spell_script_names` WHERE `spell_id` = 114923 AND `ScriptName` = 'spell_mage_nether_tempest';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (114923, 'spell_mage_nether_tempest');

DELETE FROM `spell_script_names` WHERE `spell_id` = 210805 AND `ScriptName` = 'spell_mage_time_anomaly';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (210805, 'spell_mage_time_anomaly');

DELETE FROM `spell_script_names` WHERE `spell_id` = 236628 AND `ScriptName` = 'spell_mage_amplification';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (236628, 'spell_mage_amplification');

DELETE FROM `spell_script_names` WHERE `spell_id` = 210126 AND `ScriptName` = 'spell_mage_arcane_familiar';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (210126, 'spell_mage_arcane_familiar');
