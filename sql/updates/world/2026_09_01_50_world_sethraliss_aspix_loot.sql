-- 837 blizzlike: Temple of Sethraliss map 1877 Aspix 133944 has lootid=0 and zero Journal 2142 rows; set lootid=133944 and insert the same ten handbook items as Adderis 133379. Chance copies Adderis 20, NOT DBC, GroupId=0. Do not DELETE 133379. Do not INSERT 168154. Do not SET lootid on trash. Do not touch _32-_49. Do not INSERT instance_encounters. Do not UPDATE 2096.

DELETE FROM `creature_loot_template` WHERE `Entry`=133944 AND `Item` IN (159317, 159380, 158370, 159259, 159425, 159329, 159636, 159388, 159263, 159435);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(133944, 159317, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159380, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 158370, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159259, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159425, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159329, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159636, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159388, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159263, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC'),
(133944, 159435, 0, 20, 0, 1, 0, 1, 1, 'Aspix 133944 Journal 2142; Chance copies Adderis 20, NOT DBC');

UPDATE `creature_template` SET `lootid`=133944 WHERE `entry`=133944;
