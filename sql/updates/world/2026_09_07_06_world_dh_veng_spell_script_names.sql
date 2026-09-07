-- 837 blizzlike: 烈火烙印卸 204022 吸收错形。裂伤改 263642，卸军团 209795。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 204022 AND `ScriptName` = 'spell_dh_fiery_brand_absorb';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 209795 AND `ScriptName` = 'spell_dh_fracture';
DELETE FROM `spell_script_names` WHERE `spell_id` = 263642 AND `ScriptName` = 'spell_dh_fracture';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (263642, 'spell_dh_fracture');
