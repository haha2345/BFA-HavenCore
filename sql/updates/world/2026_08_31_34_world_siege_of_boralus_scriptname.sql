-- 837 blizzlike: map 1822 Enable NPCs 128650/128649/128651 have empty ScriptName (SmartAI); hang factories on Enable ids. Do not spawn 144160/130836. Do not UPDATE 128652/129208 (already aligned). Do not touch 130834/144158/129415/120553.
UPDATE `creature_template` SET `ScriptName`='boss_chopper_redhook' WHERE `entry`=128650;
UPDATE `creature_template` SET `ScriptName`='boss_sergeant_bainbridge' WHERE `entry`=128649;
UPDATE `creature_template` SET `ScriptName`='boss_hadal_darkfathom' WHERE `entry`=128651;
