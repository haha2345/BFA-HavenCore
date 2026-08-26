-- 837 blizzlike: Twilight beam AT id is 23070, not 2307.
-- spell_areatrigger (official dump) maps SpellMiscId 19034 -> AreaTriggerId 23070
-- (cylinder r=3, h=10, ZOffset 0.3, VerifiedBuild 34220). 2026_08_25_01 created an
-- unused sphere 2307 and hung at_twilight_devastation there, so OnUnitEnter never ran.

UPDATE `areatrigger_template`
SET `ScriptName` = 'at_twilight_devastation'
WHERE `Id` = 23070;

DELETE FROM `areatrigger_template`
WHERE `Id` = 2307 AND `ScriptName` = 'at_twilight_devastation';
