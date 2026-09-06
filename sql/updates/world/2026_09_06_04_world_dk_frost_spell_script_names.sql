-- 837 blizzlike: 凛风 49184 不要走冰触脚本。巨龙之怒 279302 缺家；DBC AT Misc0=14881。
-- 禁止把枯萎效果 3 基点 26 写进本文件。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 49184 AND `ScriptName` = 'spell_dk_icy_touch';

DELETE FROM `spell_script_names` WHERE `spell_id` = 279302 AND `ScriptName` = 'spell_dk_frostwyrms_fury';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (279302, 'spell_dk_frostwyrms_fury');

DELETE FROM `areatrigger_template` WHERE `Id` = 14881;
INSERT INTO `areatrigger_template`
    (`Id`, `Type`, `Flags`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `ScriptName`, `VerifiedBuild`)
VALUES
    (14881, 0, 0, 40, 40, 0, 0, 0, 0, 'at_dk_frostwyrms_fury', 35662);

DELETE FROM `spell_areatrigger` WHERE `SpellMiscId` = 14881;
INSERT INTO `spell_areatrigger`
    (`SpellMiscId`, `AreaTriggerId`, `MoveCurveId`, `ScaleCurveId`, `MorphCurveId`, `FacingCurveId`,
     `AnimId`, `AnimKitId`, `DecalPropertiesId`, `TimeToTarget`, `TimeToTargetScale`, `VerifiedBuild`)
VALUES
    (14881, 14881, 0, 0, 0, 0, 0, 0, 0, 0, 10000, 35662);
