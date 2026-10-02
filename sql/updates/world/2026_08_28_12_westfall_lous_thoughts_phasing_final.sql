-- BFA-HavenCore

INSERT IGNORE INTO `phase_area` (`AreaId`, `PhaseId`, `Comment`) VALUES (40, 170, 'Westfall - Pre-Quest NPCs');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 26 AND `SourceGroup` = 170 AND `SourceEntry` = 40;
INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
     `NegativeCondition`, `Comment`)
VALUES
(26, 170, 40, 0, 0, 47, 0, 26232, 66, 0, 1, '');

UPDATE `creature`
SET `PhaseId` = 170, `PhaseUseFlags` = 0, `PhaseGroup` = 0
WHERE `guid` IN (214427, 214362, 214354, 214357, 214359);

UPDATE `creature`
SET `PhaseId` = 170, `PhaseUseFlags` = 0, `PhaseGroup` = 0
WHERE `id` IN (42383, 42384, 42385, 42386)
  AND `map` = 0
  AND `guid` NOT IN (10678110, 10678111, 10678112)
  AND `position_y` BETWEEN 1270 AND 1340
  AND `position_x` BETWEEN -9900 AND -9820;

UPDATE `creature`
SET `PhaseId` = 0, `PhaseUseFlags` = 1, `PhaseGroup` = 0
WHERE `guid` IN (214380, 214381);

UPDATE `creature`
SET `PhaseUseFlags` = 0
WHERE `guid` IN (10678110, 10678111, 10678112);

UPDATE `creature`
SET `PhaseUseFlags` = 0
WHERE `id` IN (42383, 42384, 42385, 42386)
  AND `map` = 0
  AND `PhaseId` != 0
  AND `PhaseUseFlags` = 1;

UPDATE `creature_template`
SET `ScriptName` = 'npc_westfall_two_shoed_lou'
WHERE `entry` = 42405;
