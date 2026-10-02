-- Fix issue 505 properly (Correct condition parameters for SmartEvent and AreaID)

-- Delete old incorrectly parametered conditions
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 721 AND `SourceEntry` = 0;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 721 AND `SourceId` = 0;

-- Insert proper conditions for Rabbit (entry 721), SmartScript (id 0) to only trigger in Northshire Areas
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 721, 0, 0, 23, 1, 87, 0, 0, 0, 0, 0, '', 'Rabbit casts Terrified only in Northshire Valley'),
(22, 1, 721, 0, 1, 23, 1, 88, 0, 0, 0, 0, 0, '', 'Rabbit casts Terrified only in Northshire Abbey'),
(22, 1, 721, 0, 2, 23, 1, 89, 0, 0, 0, 0, 0, '', 'Rabbit casts Terrified only in Northshire Vineyards');
