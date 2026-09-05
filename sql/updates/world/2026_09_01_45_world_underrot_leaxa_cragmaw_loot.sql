-- 837 blizzlike: Underrot map 1841 Elder Leaxa 131318 and Cragmaw 131817 have lootid=0 and zero JournalEncounterItem rows; set lootid=entry and insert handbook items. Chance copies Zancha 131383 magnitude (1/1/1/2/2/3/9/3 plus two extra 1/2), NOT DBC, GroupId=0. Item defs are ItemSparse DB2 — do not INSERT item_template. 159324 in creature_template is Huojin Defender, loot Item is still Blood Elder's Bindings. Do not DELETE 131383/133007. Do not SET lootid on trash. Do not touch _32-_44. Do not INSERT instance_encounters. Do not UPDATE 2096.

DELETE FROM `creature_loot_template` WHERE `Entry`=131318 AND `Item` IN (159324, 159402, 159463, 159624, 159652, 159443);
DELETE FROM `creature_loot_template` WHERE `Entry`=131817 AND `Item` IN (159344, 159382, 159325, 159396, 159433, 159134, 159653, 159269, 159436, 159275);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131318, 159324, 0, 1, 0, 1, 0, 1, 1, NULL),
(131318, 159402, 0, 1, 0, 1, 0, 1, 1, NULL),
(131318, 159463, 0, 1, 0, 1, 0, 1, 1, NULL),
(131318, 159624, 0, 2, 0, 1, 0, 1, 1, NULL),
(131318, 159652, 0, 2, 0, 1, 0, 1, 1, NULL),
(131318, 159443, 0, 3, 0, 1, 0, 1, 1, NULL),
(131817, 159344, 0, 1, 0, 1, 0, 1, 1, NULL),
(131817, 159382, 0, 1, 0, 1, 0, 1, 1, NULL),
(131817, 159325, 0, 1, 0, 1, 0, 1, 1, NULL),
(131817, 159396, 0, 2, 0, 1, 0, 1, 1, NULL),
(131817, 159433, 0, 2, 0, 1, 0, 1, 1, NULL),
(131817, 159134, 0, 3, 0, 1, 0, 1, 1, NULL),
(131817, 159653, 0, 9, 0, 1, 0, 1, 1, NULL),
(131817, 159269, 0, 3, 0, 1, 0, 1, 1, NULL),
(131817, 159436, 0, 1, 0, 1, 0, 1, 1, NULL),
(131817, 159275, 0, 2, 0, 1, 0, 1, 1, NULL);

UPDATE `creature_template` SET `lootid`=`entry` WHERE `entry` IN (131318, 131817);
