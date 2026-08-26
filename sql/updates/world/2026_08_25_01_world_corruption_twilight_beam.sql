-- 837 blizzlike: Twilight Devastation traveling beam (CREATE_AREATRIGGER 19034).
-- spell_areatrigger already maps SpellMiscId 19034 -> AreaTriggerId 2307, TimeToTarget 4000.
-- Template 2307 was missing so the AT never spawned. Sphere radius 3 = DBC 317155 radius.
-- Spline X=28 yd: player reports 25-30 (Wowhead); DBC has no beam length field.
-- ScriptName hits on enter; no 6-10 falloff (intentional, not the Feb 2020 hotfix).

DELETE FROM `areatrigger_template` WHERE `Id` = 2307;
INSERT INTO `areatrigger_template` (`Id`, `Type`, `Flags`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `ScriptName`, `VerifiedBuild`) VALUES
(2307, 0, 8, 3, 3, 0, 0, 0, 0, 'at_twilight_devastation', 35662);

DELETE FROM `spell_areatrigger_splines` WHERE `SpellMiscId` = 19034;
INSERT INTO `spell_areatrigger_splines` (`SpellMiscId`, `Idx`, `X`, `Y`, `Z`, `VerifiedBuild`) VALUES
(19034, 0,  0, 0, 0, 35662),
(19034, 1,  0, 0, 0, 35662),
(19034, 2, 28, 0, 0, 35662),
(19034, 3, 28, 0, 0, 35662);

DELETE FROM `spell_script_names` WHERE `spell_id` = 317155 AND `ScriptName` = 'spell_twilight_devastation_beam';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(317155, 'spell_twilight_devastation_beam');
