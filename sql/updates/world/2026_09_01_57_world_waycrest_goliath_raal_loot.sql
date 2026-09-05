-- 837 blizzlike: Waycrest Manor map 1862 Soulbound Goliath 131667 and Raal 131863 have lootid=0 and zero Journal 2126/2127 rows; set each lootid to self and insert handbook items. Chance copies 135360 20, NOT DBC, GroupId=0. Do not INSERT 163833. Do not SET lootid on 133361/136541. Do not DELETE 135360. Do not SET lootid on trash. Do not touch _32-_56. Do not INSERT instance_encounters. Do not UPDATE 2096/2113-2117/2124-2127/2105-2108.

DELETE FROM `creature_loot_template` WHERE `Entry`=131667 AND `Item` IN (159399, 162548, 159282, 159341, 159630, 159659, 159456);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131667, 159399, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC'),
(131667, 162548, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC'),
(131667, 159282, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC'),
(131667, 159341, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC'),
(131667, 159630, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC'),
(131667, 159659, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC'),
(131667, 159456, 0, 20, 0, 1, 0, 1, 1, 'Soulbound Goliath 131667 Journal 2126; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131667 WHERE `entry`=131667;

DELETE FROM `creature_loot_template` WHERE `Entry`=131863 AND `Item` IN (159660, 159616, 159452, 159285, 159346, 159397, 159294);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131863, 159660, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC'),
(131863, 159616, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC'),
(131863, 159452, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC'),
(131863, 159285, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC'),
(131863, 159346, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC'),
(131863, 159397, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC'),
(131863, 159294, 0, 20, 0, 1, 0, 1, 1, 'Raal 131863 Journal 2127; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131863 WHERE `entry`=131863;
