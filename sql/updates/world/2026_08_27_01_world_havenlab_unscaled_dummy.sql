-- HavenLab: unscaled dummy for A4 tentacle CLEU vs script amount.
-- 31146 has creature_template_scaling 85-90 and npc_training_dummy zeros HP.
-- 190001: level 120, no scaling row, real damage, PACIFIED, no AI.
-- Do NOT insert creature_template_scaling for this entry.

DELETE FROM `creature_template_scaling` WHERE `Entry` = 190001;
DELETE FROM `creature_template_addon` WHERE `entry` = 190001;
DELETE FROM `creature_template_locale` WHERE `entry` = 190001;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 190001;
DELETE FROM `creature_template` WHERE `entry` = 190001;

INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `HealthScalingExpansion`, `RequiredExpansion`,
 `faction`, `unit_class`, `unit_flags`, `unit_flags2`, `unit_flags3`, `type`, `type_flags`,
 `AIName`, `ScriptName`, `InhabitType`, `HealthModifier`, `HealthModifierExtra`, `DamageModifier`,
 `BaseAttackTime`, `RegenHealth`, `flags_extra`, `VerifiedBuild`)
VALUES
(190001, 'HavenLab Unscaled Dummy', 'no scaling', 120, 120, 7, 0,
 7, 1, 131072, 2048, 1, 9, 524292,
 '', '', 1, 1400, 1, 1,
 2000, 0, 262208, 35662);

INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
(190001, 0, 27510, 1, 1, 35662);

INSERT INTO `creature_template_locale`
(`entry`, `locale`, `Name`, `NameAlt`, `Title`, `TitleAlt`, `VerifiedBuild`)
VALUES
(190001, 'zhCN', 'HavenLab无缩放桩', '', '无缩放 真掉血', NULL, 35662);
