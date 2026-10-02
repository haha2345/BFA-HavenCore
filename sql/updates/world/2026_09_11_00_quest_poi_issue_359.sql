-- Direct sniff which fixes issue 359
-- TrinityCore - WowPacketParser
-- Detected build: V12_1_0_69587
-- Detected locale: enUS
-- Targeted database: BattleForAzeroth

DELETE FROM `quest_poi` WHERE (`QuestID`=31145 AND `BlobIndex`=0 AND `Idx1`=0) OR (`QuestID`=31144 AND `BlobIndex`=0 AND `Idx1`=1) OR (`QuestID`=31144 AND `BlobIndex`=0 AND `Idx1`=0) OR (`QuestID`=31143 AND `BlobIndex`=1 AND `Idx1`=2) OR (`QuestID`=31143 AND `BlobIndex`=0 AND `Idx1`=1) OR (`QuestID`=31143 AND `BlobIndex`=0 AND `Idx1`=0) OR (`QuestID`=31140 AND `BlobIndex`=1 AND `Idx1`=3) OR (`QuestID`=31140 AND `BlobIndex`=0 AND `Idx1`=2) OR (`QuestID`=31140 AND `BlobIndex`=0 AND `Idx1`=1) OR (`QuestID`=31140 AND `BlobIndex`=0 AND `Idx1`=0) OR (`QuestID`=31139 AND `BlobIndex`=0 AND `Idx1`=2) OR (`QuestID`=31139 AND `BlobIndex`=0 AND `Idx1`=1) OR (`QuestID`=31139 AND `BlobIndex`=0 AND `Idx1`=0);
INSERT INTO `quest_poi` (`QuestID`, `BlobIndex`, `Idx1`, `ObjectiveIndex`, `QuestObjectiveID`, `QuestObjectID`, `MapID`, `UiMapID`, `Priority`, `Flags`, `WorldEffectID`, `PlayerConditionID`, `SpawnTrackingID`, `AlwaysAllowMergingBlobs`, `VerifiedBuild`) VALUES
(31144, 0, 1, 0, 268171, 50039, 0, 425, 0, 1, 0, 0, 0, 0, 69587), -- 31144
(31144, 0, 0, -1, 0, 0, 0, 425, 0, 1, 0, 0, 0, 0, 69587); -- 31144

DELETE FROM `quest_poi_points` WHERE (`QuestID`=31145 AND `Idx1`=0 AND `Idx2`=0) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=6) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=5) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=4) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=3) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=2) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=1) OR (`QuestID`=31144 AND `Idx1`=1 AND `Idx2`=0) OR (`QuestID`=31144 AND `Idx1`=0 AND `Idx2`=0) OR (`QuestID`=31143 AND `Idx1`=2 AND `Idx2`=0) OR (`QuestID`=31143 AND `Idx1`=1 AND `Idx2`=0) OR (`QuestID`=31143 AND `Idx1`=0 AND `Idx2`=0) OR (`QuestID`=31140 AND `Idx1`=3 AND `Idx2`=0) OR (`QuestID`=31140 AND `Idx1`=2 AND `Idx2`=0) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=6) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=5) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=4) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=3) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=2) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=1) OR (`QuestID`=31140 AND `Idx1`=1 AND `Idx2`=0) OR (`QuestID`=31140 AND `Idx1`=0 AND `Idx2`=0) OR (`QuestID`=31139 AND `Idx1`=2 AND `Idx2`=0) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=9) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=8) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=7) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=6) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=5) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=4) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=3) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=2) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=1) OR (`QuestID`=31139 AND `Idx1`=1 AND `Idx2`=0) OR (`QuestID`=31139 AND `Idx1`=0 AND `Idx2`=0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(31144, 1, 6, -8809, -257, 69587), -- 31144
(31144, 1, 5, -8826, -213, 69587), -- 31144
(31144, 1, 4, -8771, -102, 69587), -- 31144
(31144, 1, 3, -8752, -89, 69587), -- 31144
(31144, 1, 2, -8691, -78, 69587), -- 31144
(31144, 1, 1, -8728, -201, 69587), -- 31144
(31144, 1, 0, -8767, -279, 69587), -- 31144
(31144, 0, 0, -8828, -159, 69587); -- 31144
