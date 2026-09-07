-- 837 blizzlike: 奇袭毒药炸弹/吸血/盲目侧击/淬毒/放血。卸 703 披风与匕首、卸 108211。
-- 禁止 INSERT 79140/185565/196864/108211/112961/255989 空壳（刺客大师窗口写在潜行脚本）。
-- 禁止 INSERT 1766/185311。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 703 AND `ScriptName` = 'spell_rog_cloak_and_dagger';
DELETE FROM `spell_script_names`
WHERE `spell_id` = 108211 AND `ScriptName` = 'spell_rog_poisons';

DELETE FROM `spell_script_names` WHERE `spell_id` = 280716 AND `ScriptName` = 'spell_rog_leeching_poison';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (280716, 'spell_rog_leeching_poison');

DELETE FROM `spell_script_names` WHERE `spell_id` = 111240 AND `ScriptName` = 'spell_rog_blindside';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (111240, 'spell_rog_blindside');

DELETE FROM `spell_script_names` WHERE `spell_id` = 200806 AND `ScriptName` = 'spell_rog_exsanguinate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (200806, 'spell_rog_exsanguinate');

-- Spell AT 走 areatrigger_template.ScriptName；areatrigger_scripts 运行时跳过。
UPDATE `areatrigger_template` SET `ScriptName`='at_rog_poison_bomb' WHERE `Id`=11866;

-- 11866 dump 无行，上面 UPDATE 是空操作。行不存在则 INSERT。Type/半径抄自 16552（同 6 码圈）。
DELETE FROM `areatrigger_template` WHERE `Id` = 11866;
INSERT INTO `areatrigger_template`
    (`Id`, `Type`, `Flags`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `ScriptName`, `VerifiedBuild`)
VALUES
    (11866, 4, 0, 6, 6, 0, 0, 0, 0, 'at_rog_poison_bomb', 35662);

UPDATE `spell_areatrigger` SET `AreaTriggerId`=11866, `VerifiedBuild`=35662 WHERE `SpellMiscId`=11866;
