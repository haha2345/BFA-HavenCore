-- 837 blizzlike: Freehold — drop holiday hat and mythic keystone junk; Sharkbait 159842 only on Mythic (difficulty 23).

DELETE FROM `creature_loot_template` WHERE `Entry`=126832 AND `Item`=139299;
DELETE FROM `creature_loot_template` WHERE `Entry`=126983 AND `Item`=158923;

-- Keep 159842 Chance=21. Do not UPDATE that loot row. Other Harlan rows stay.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=1 AND `SourceGroup`=126983 AND `SourceEntry`=159842 AND `ConditionTypeOrReference`=49;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(1, 126983, 159842, 0, 0, 49, 0, 23, 0, 0, 0, 0, 0, '', 'Harlan Sweete 126983 - 159842 only on difficulty 23');
