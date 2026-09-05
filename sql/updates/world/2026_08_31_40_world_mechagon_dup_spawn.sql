-- 837 blizzlike: map 2097 King Gobbamak and Gunker each have two overlapping creature rows. Keep 3300000000000694 / 3300000000000898 (VerifiedBuild=31478, creature_addon 297701 / 300859). Delete 2103360742572 / 2103360742575. Do not invent a third xyz.
DELETE FROM `creature` WHERE `map`=2097 AND `guid` IN (2103360742572, 2103360742575);
