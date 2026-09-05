-- 837 blizzlike: Align Harlan Sweete 126983 creature_text GroupID with C++ HarlanTalk (0-5).

-- Dump Groups 0-3 were shifted vs C++: death yelled cannon, grenadier yelled death; Groups 4-5 missing.
-- Group 0 aggro unchanged. Group 1 keeps "Men! Acquaint..." as 60%/All Hands (F3).
-- Group 2 death = dump Group 3 Inconceivable. Group 3 grenadier = 35662 broadcast_text 140646.
-- Group 4 cannon = dump Group 2. Group 5 30%/Man-O-War = 35662 broadcast_text 140656 (no dedicated Man-O-War yell).
-- Do not touch council captains (Task 4 19). Do not invent Gukguk/Gurgthock.

DELETE FROM `creature_text` WHERE `CreatureID`=126983;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(126983, 0, 0, 'Think you can stand against me, swine? Allow me to educate you.', 14, 0, 100, 1, 0, 97284, 140566, 0, 'Harlan Sweete - TalkAggro'),
(126983, 1, 0, 'Men! Acquaint these scallywags with our heavy guns.', 14, 0, 100, 11, 0, 97283, 140653, 0, 'Harlan Sweete - Talk60Percent'),
(126983, 2, 0, 'Inconceivable...', 14, 0, 100, 21, 0, 97286, 140654, 0, 'Harlan Sweete - TalkDead'),
(126983, 3, 0, 'Swab the deck with their gizzards!', 14, 0, 100, 0, 0, 97281, 140646, 0, 'Harlan Sweete - TalkGranadier'),
(126983, 4, 0, 'Cannons! Blast these scurvy dogs to bits!', 14, 0, 100, 4, 0, 97282, 140652, 0, 'Harlan Sweete - TalkCannon'),
(126983, 5, 0, 'Taller men than you have opposed me, but they always came up short.', 14, 0, 100, 0, 0, 97285, 140656, 0, 'Harlan Sweete - Talk30Percent');
