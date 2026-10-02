-- Fix issue 505: Rabbits should only be terrified in Northshire
-- Limit the Terrified cast (smart script event) to rabbits located in Northshire areas

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 721 AND `SourceEntry` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 721, 0, 0, 0, 22, 1, 87, 0, 0, 0, 0, 0, '', 'Rabbit casts Terrified only in Northshire Valley'),
(22, 721, 0, 0, 1, 22, 1, 88, 0, 0, 0, 0, 0, '', 'Rabbit casts Terrified only in Northshire Abbey'),
(22, 721, 0, 0, 2, 22, 1, 89, 0, 0, 0, 0, 0, '', 'Rabbit casts Terrified only in Northshire Vineyards');
