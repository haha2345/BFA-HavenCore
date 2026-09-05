-- 837 blizzlike: Waycrest Manor map 1862 Lord 131527 and Lady 131545 have lootid=0 and zero Journal 2128 rows; set each lootid to self and insert seven handbook items. Chance copies 135360 20, NOT DBC, GroupId=0. Do not DELETE 135360. Do not SET lootid on trash. Do not touch _32-_57. Do not INSERT instance_encounters. Do not UPDATE 2096/2113-2117/2124-2127/2105-2108.

DELETE FROM `creature_loot_template` WHERE `Entry`=131527 AND `Item` IN (159262, 159347, 159403, 159457, 159661, 158362, 159631);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131527, 159262, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131527, 159347, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131527, 159403, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131527, 159457, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131527, 159661, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131527, 158362, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131527, 159631, 0, 20, 0, 1, 0, 1, 1, 'Lord Waycrest 131527 Journal 2128; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131527 WHERE `entry`=131527;

DELETE FROM `creature_loot_template` WHERE `Entry`=131545 AND `Item` IN (159262, 159347, 159403, 159457, 159661, 158362, 159631);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131545, 159262, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131545, 159347, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131545, 159403, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131545, 159457, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131545, 159661, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131545, 158362, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC'),
(131545, 159631, 0, 20, 0, 1, 0, 1, 1, 'Lady Waycrest 131545 Journal 2128; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131545 WHERE `entry`=131545;
