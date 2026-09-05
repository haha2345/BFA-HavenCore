-- 837 blizzlike: Underrot Unbound Abomination 133007 already has Mythic Keystone 158923 Chance=2 in creature_loot_template. Add CONDITION_DIFFICULTY_ID=23 (same column order as 2026_08_30_15 Harlan 159842/126983). Do not DELETE the loot row. Do not change Chance. Do not UPDATE 131383/133007 other loot. Do not UPDATE 2096. Do not touch _32-_44 or _45.

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=1 AND `SourceGroup`=133007 AND `SourceEntry`=158923 AND `ConditionTypeOrReference`=49;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(1, 133007, 158923, 0, 0, 49, 0, 23, 0, 0, 0, 0, 0, '', 'Unbound Abomination 133007 - 158923 only on difficulty 23');
