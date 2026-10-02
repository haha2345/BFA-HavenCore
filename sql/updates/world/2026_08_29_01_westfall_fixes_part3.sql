-- BFA-HavenCore

UPDATE `quest_objectives`
SET `Description` = 'Westfall Homeless fed'
WHERE `QuestID` = 26271;

UPDATE `quest_objectives`
SET `Description` = 'Attacking Riverpaw Gnoll slain'
WHERE `QuestID` = 26286;

UPDATE `quest_objectives`
SET `Description` = 'Information from Moonbrook Rally gathered'
WHERE `QuestID` = 26297;

-- The Coastal Menace
DELETE FROM `creature_queststarter`
WHERE `quest` = 26951;
DELETE FROM `creature_questender`
WHERE `quest` = 26951;