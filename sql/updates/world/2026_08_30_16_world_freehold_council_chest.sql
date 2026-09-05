-- 837 blizzlike: Freehold Council's Tribute 288636 — set Data1 to its loot id and insert the eight council items.

UPDATE `gameobject_template` SET `Data1`=288636 WHERE `entry`=288636;

DELETE FROM `gameobject_loot_template` WHERE `Entry`=288636;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(288636, 159132, 0, 8, 0, 1, 1, 1, 1, ''),
(288636, 159130, 0, 6, 0, 1, 1, 1, 1, ''),
(288636, 158311, 0, 4, 0, 1, 1, 1, 1, ''),
(288636, 159356, 0, 4, 0, 1, 1, 1, 1, ''),
(288636, 158346, 0, 4, 0, 1, 1, 1, 1, ''),
(288636, 159297, 0, 4, 0, 1, 1, 1, 1, ''),
(288636, 158351, 0, 4, 0, 1, 1, 1, 1, ''),
(288636, 158314, 0, 3, 0, 1, 1, 1, 1, '');
