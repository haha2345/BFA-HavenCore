-- 837 blizzlike: Temple of Sethraliss map 1877 Galvazzt 133389 has lootid=0 and zero Journal 2144 rows; set lootid=133389 and insert six handbook items. Chance copies Adderis 20, NOT DBC, GroupId=0. Do not INSERT 168154. Do not DELETE 133379/133944. Do not SET lootid on trash. Do not touch _32-_50. Do not INSERT instance_encounters. Do not UPDATE 2096.

DELETE FROM `creature_loot_template` WHERE `Entry`=133389 AND `Item` IN (159247, 159442, 158374, 158366, 158369, 159664);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(133389, 159247, 0, 20, 0, 1, 0, 1, 1, 'Galvazzt 133389 Journal 2144; Chance copies Adderis 20, NOT DBC'),
(133389, 159442, 0, 20, 0, 1, 0, 1, 1, 'Galvazzt 133389 Journal 2144; Chance copies Adderis 20, NOT DBC'),
(133389, 158374, 0, 20, 0, 1, 0, 1, 1, 'Galvazzt 133389 Journal 2144; Chance copies Adderis 20, NOT DBC'),
(133389, 158366, 0, 20, 0, 1, 0, 1, 1, 'Galvazzt 133389 Journal 2144; Chance copies Adderis 20, NOT DBC'),
(133389, 158369, 0, 20, 0, 1, 0, 1, 1, 'Galvazzt 133389 Journal 2144; Chance copies Adderis 20, NOT DBC'),
(133389, 159664, 0, 20, 0, 1, 0, 1, 1, 'Galvazzt 133389 Journal 2144; Chance copies Adderis 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=133389 WHERE `entry`=133389;
