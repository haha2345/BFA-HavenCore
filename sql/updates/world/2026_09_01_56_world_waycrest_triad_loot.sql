-- 837 blizzlike: Waycrest Manor map 1862 Heartsbane Triad 131823/131824/131825 have lootid=0 and zero Journal 2125 rows on combat entries; set each lootid to self and insert the same nine handbook items as intro Sister Briar 135360. Chance copies 135360 20, NOT DBC, GroupId=0. Do not DELETE 135360. Do not SET lootid on trash. Do not touch _32-_55. Do not INSERT instance_encounters. Do not UPDATE 2096/2113-2117/2124-2127/2105-2108.

DELETE FROM `creature_loot_template` WHERE `Entry`=131823 AND `Item` IN (159272, 159340, 159345, 159404, 159133, 159400, 159449, 159669, 159450);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131823, 159272, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159340, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159345, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159404, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159133, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159400, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159449, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159669, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131823, 159450, 0, 20, 0, 1, 0, 1, 1, 'Sister Malady 131823 Journal 2125; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131823 WHERE `entry`=131823;

DELETE FROM `creature_loot_template` WHERE `Entry`=131824 AND `Item` IN (159272, 159340, 159345, 159404, 159133, 159400, 159449, 159669, 159450);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131824, 159272, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159340, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159345, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159404, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159133, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159400, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159449, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159669, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131824, 159450, 0, 20, 0, 1, 0, 1, 1, 'Sister Solena 131824 Journal 2125; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131824 WHERE `entry`=131824;

DELETE FROM `creature_loot_template` WHERE `Entry`=131825 AND `Item` IN (159272, 159340, 159345, 159404, 159133, 159400, 159449, 159669, 159450);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(131825, 159272, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159340, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159345, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159404, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159133, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159400, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159449, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159669, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC'),
(131825, 159450, 0, 20, 0, 1, 0, 1, 1, 'Sister Briar 131825 Journal 2125; Chance copies 135360 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=131825 WHERE `entry`=131825;
