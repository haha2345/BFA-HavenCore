-- 837 blizzlike: 257093 CREATE_AREATRIGGER MiscValue=11991 has no spell_areatrigger row; ground AI areatrigger_sand_trap never binds. Radius 4 is min-playable, not verified 8.3 sniff. Do not reuse template 16810.
INSERT INTO `areatrigger_template` (`Id`, `Type`, `Flags`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `ScriptName`, `VerifiedBuild`) VALUES
	(11991, 0, 0, 4, 4, 0, 0, 0, 0, 'areatrigger_sand_trap', 35662);

INSERT INTO `spell_areatrigger` (`SpellMiscId`, `AreaTriggerId`, `MoveCurveId`, `ScaleCurveId`, `MorphCurveId`, `FacingCurveId`, `AnimId`, `AnimKitId`, `DecalPropertiesId`, `TimeToTarget`, `TimeToTargetScale`, `VerifiedBuild`) VALUES
	(11991, 11991, 0, 0, 0, 0, 0, 0, 0, 0, 0, 35662);
