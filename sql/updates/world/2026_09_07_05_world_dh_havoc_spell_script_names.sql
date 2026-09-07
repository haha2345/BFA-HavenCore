-- 837 blizzlike: 浩劫献祭改 258920；冲刺伤改 192611；弹幕卸军团 211053；
-- 第一滴血改绑伤害号；死亡扫描接刃舞主脚本；恶魔之咬接无餍饥饿。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 178740 AND `ScriptName` = 'spell_dh_immolation_aura';
DELETE FROM `spell_script_names` WHERE `spell_id` = 258920 AND `ScriptName` = 'spell_dh_immolation_aura';
DELETE FROM `spell_script_names` WHERE `spell_id` = 258921 AND `ScriptName` = 'spell_dh_immolation_aura_initial';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (258920, 'spell_dh_immolation_aura'),
    (258921, 'spell_dh_immolation_aura_initial');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 223107 AND `ScriptName` = 'spell_dh_fel_rush_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 192611 AND `ScriptName` = 'spell_dh_fel_rush_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (192611, 'spell_dh_fel_rush_damage');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 211053 AND `ScriptName` = 'spell_dh_fel_barrage';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 206416 AND `ScriptName` = 'spell_dh_first_blood';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (199552, 200685, 210153, 210155) AND `ScriptName` = 'spell_dh_first_blood';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (199552, 'spell_dh_first_blood'),
    (200685, 'spell_dh_first_blood'),
    (210153, 'spell_dh_first_blood'),
    (210155, 'spell_dh_first_blood');

DELETE FROM `spell_script_names` WHERE `spell_id` = 210152 AND `ScriptName` = 'spell_demon_hunter_blade_dance_main';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (210152, 'spell_demon_hunter_blade_dance_main');

DELETE FROM `spell_script_names` WHERE `spell_id` = 162243 AND `ScriptName` = 'spell_dh_demons_bite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (162243, 'spell_dh_demons_bite');
