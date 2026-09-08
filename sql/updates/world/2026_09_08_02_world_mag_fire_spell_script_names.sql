-- 837 blizzlike: 火焰凤凰257541/炎爆冲击；卸 Flurry 44614 点燃错绑；补烈焰风暴点燃。
-- 禁止 INSERT 194466/269644/205033/198929 空壳。禁止 DELETE 194466 dump。禁止 INSERT 257541 到 spell_arti_mage_phoenix_flames。
DELETE FROM `spell_script_names` WHERE `spell_id` = 257541 AND `ScriptName` = 'spell_mage_phoenix_flames';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (257541, 'spell_mage_phoenix_flames');

DELETE FROM `spell_script_names` WHERE `spell_id` = 269650 AND `ScriptName` = 'spell_mage_pyroclasm';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (269650, 'spell_mage_pyroclasm');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 44614 AND `ScriptName` = 'spell_mastery_ignite';

DELETE FROM `spell_script_names` WHERE `spell_id` = 2120 AND `ScriptName` = 'spell_mastery_ignite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (2120, 'spell_mastery_ignite');
