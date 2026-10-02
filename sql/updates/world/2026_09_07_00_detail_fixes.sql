-- Fix Young Wolf (Entry 299) state flags
UPDATE `creature_template` SET `unit_flags` = 0, `unit_flags3` = 0 WHERE `entry` = 299;

-- Fix Mutual Aid (13576) objective
UPDATE `quest_objectives` 
SET `Description` = 'Unbound Fire Elemental absorbed' 
WHERE `QuestID` = 13576;

-- Update Gug Fatcandle (Entry 62) to Rare Rank
UPDATE `creature_template` 
SET `rank` = 2 
WHERE `entry` = 62;