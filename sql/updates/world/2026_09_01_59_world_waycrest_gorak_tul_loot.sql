-- 837 blizzlike: Waycrest Manor map 1862 Gorak Tul 131864 has lootid=0 and zero Journal 2129 rows on the combat entry; set lootid=131864 and insert the same nine handbook items as 144324. Chance copies 144324 20, NOT DBC, GroupId=0. Do not DELETE 144324. Do not UPDATE 144324 flags. Do not INSERT 168125. Do not SET lootid on 135552. Do not SET lootid on trash. Do not touch _32-_58. Do not INSERT instance_encounters. Do not UPDATE 2096/2113-2117/2124-2127/2105-2108.

DELETE FROM `creature_loot_template` WHERE `Entry`=131864 AND `Item` IN (159448, 159662, 159335, 159395, 159273, 159339, 159279, 159455, 159398);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131864, 159448, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159662, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159335, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159395, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159273, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159339, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159279, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159455, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC'),
(131864, 159398, 0, 20, 0, 1, 0, 1, 1, 'Gorak Tul 131864 Journal 2129; Chance copies 144324 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131864 WHERE `entry`=131864;
