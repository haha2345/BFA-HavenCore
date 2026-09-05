-- 837 blizzlike: Align council captain creature_text GroupID with C++ Talk enums (Jolly 0-3, Eudora 0-1, Raoul 0).

-- Dump (DatabasesV1.1/bfa_world creature_text): 126845 Group 0 En guard! / Group 1 death; 126848 Group 0 death only; 126847 no rows.
-- C++ TextJolly: 0 whirlpool, 1 cutting surge, 2 death, 3 aggro. TextEudora: 0 death, 1 aggro. TextRaoul: 0 aggro.
-- Missing English lines use 35662 broadcast_text (hotfixes dump), not invented strings. No Gukguk/Gurgthock rows.

DELETE FROM `creature_text` WHERE `CreatureID` IN (126845, 126848, 126847);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(126845, 0, 0, 'En guard!', 14, 0, 100, 274, 0, 97245, 140572, 0, 'Captain Jolly - TalkWhirpoolBlade'),
(126845, 1, 0, 'Surging steel!', 14, 0, 100, 0, 0, 97246, 140573, 0, 'Captain Jolly - TalkCuttingSurge'),
(126845, 2, 0, 'Bury me with my blade...', 14, 0, 100, 7, 0, 97250, 140559, 0, 'Captain Jolly - TalkDeadJolly'),
(126845, 3, 0, 'Let\'s put your steel to the test!', 14, 0, 100, 0, 0, 97249, 140546, 0, 'Captain Jolly - TalkAggroJolly'),
(126848, 0, 0, 'Nice... shot...', 14, 0, 100, 4, 0, 97241, 140540, 0, 'Captain Eudora - TalkDeadEudora'),
(126848, 1, 0, 'Your skulls will be excellent target practice.', 14, 0, 100, 0, 0, 97240, 140535, 0, 'Captain Eudora - TalkAggroEudora'),
(126847, 0, 0, 'Bottoms up, scallywags!', 14, 0, 100, 0, 0, 97260, 140529, 0, 'Captain Raoul - TalkAggroRaoul');
