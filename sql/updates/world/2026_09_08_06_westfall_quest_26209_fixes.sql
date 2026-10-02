-- BFA-HavenCore

-- Murder Was The Case That They Gave Me (Quest 26209) Fixes

-- 1. Fix quest objective descriptions so UI doesn't show "Furlbrow Murder Info xxx"
UPDATE `quest_objectives` SET `Description` = 'Clue found' WHERE `QuestID` = 26209;

-- 2. Follow-up quests (26213, 26214) should require 26209
UPDATE `quest_template_addon` SET `PrevQuestID` = 26209 WHERE `ID` IN (26213, 26214);

-- 3. Homeless Stormwind Citizen and Transient NPCs should be interactable to get clues
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1, `gossip_menu_id` = 11635 WHERE `entry` IN (42386, 42384, 42383);

-- 4. Ragamuffins (42413) should say a line, run away and despawn
DELETE FROM `creature_text` WHERE `CreatureID` = 42413;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(42413, 0, 0, 'Nice boots!', 12, 0, 100, 0, 0, 0, 0, 0, 'Ragamuffin - Say'),
(42413, 0, 1, 'He ain''t needin'' these anymore...', 12, 0, 100, 0, 0, 0, 0, 0, 'Ragamuffin - Say');

-- Fix Ragamuffin move forward action to move 15 yards instead of 1 so they actually run away
UPDATE `smart_scripts` SET `action_param1` = 15 WHERE `entryorguid` = 4241300 AND `id` = 2 AND `action_type` = 46;
-- Murder Was The Case That They Gave Me (Quest 26209) Fix
-- Remove mandatory breadcrumb requirement

UPDATE `quest_template_addon` SET `PrevQuestID` = 0 WHERE `ID` = 26209;
-- Remove QuestPackageID restriction that hides the quest from the UI
UPDATE `quest_template` SET `QuestPackageID` = 0 WHERE `ID` = 26209;
-- Fix "Murder Was The Case That They Gave Me" (26209) being hidden by breadcrumb chains
-- Remove NextQuestID from Hero's Call breadcrumbs so they don't force a strict chain

UPDATE `quest_template_addon` SET `NextQuestID` = 0 WHERE `ID` IN (26378, 28562);
-- Fix "Murder Was The Case That They Gave Me" (26209) missing clues
-- Standardize KillCredit and Gossip scripts for all 4 clue-giving NPCs

-- 1. Fix KillCredits so each of the 4 NPCs gives one of the 4 clues when killed
UPDATE `creature_template` SET `KillCredit2` = 42414 WHERE `entry` = 42384;
UPDATE `creature_template` SET `KillCredit2` = 42415 WHERE `entry` = 42383;
UPDATE `creature_template` SET `KillCredit2` = 42416 WHERE `entry` = 42386;
UPDATE `creature_template` SET `KillCredit2` = 42417 WHERE `entry` = 42391;

-- 2. Delete existing broken gossip scripts (id 0 to 3) for all 4 NPCs
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (42383, 42384, 42386, 42391) AND `id` IN (0, 1, 2, 3);

-- 3. Insert fresh, working gossip scripts for all 4 NPCs

-- For 42384 (Clue 1 = 42414)
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_chance`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `target_type`, `comment`) VALUES
(42384, 0, 0, 1, 62, 100, 11635, 0, 72, 0, 7, 'On Gossip Option 0 - Close Gossip'),
(42384, 0, 1, 0, 61, 100, 0, 0, 2, 14, 1, 'Link - Set Faction Hostile'),
(42384, 0, 2, 3, 62, 100, 11635, 1, 72, 0, 7, 'On Gossip Option 1 - Close Gossip'),
(42384, 0, 3, 0, 61, 100, 0, 0, 33, 42414, 7, 'Link - Give Kill Credit');

-- For 42383 (Clue 2 = 42415)
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_chance`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `target_type`, `comment`) VALUES
(42383, 0, 0, 1, 62, 100, 11635, 0, 72, 0, 7, 'On Gossip Option 0 - Close Gossip'),
(42383, 0, 1, 0, 61, 100, 0, 0, 2, 14, 1, 'Link - Set Faction Hostile'),
(42383, 0, 2, 3, 62, 100, 11635, 1, 72, 0, 7, 'On Gossip Option 1 - Close Gossip'),
(42383, 0, 3, 0, 61, 100, 0, 0, 33, 42415, 7, 'Link - Give Kill Credit');

-- For 42386 (Clue 3 = 42416)
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_chance`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `target_type`, `comment`) VALUES
(42386, 0, 0, 1, 62, 100, 11635, 0, 72, 0, 7, 'On Gossip Option 0 - Close Gossip'),
(42386, 0, 1, 0, 61, 100, 0, 0, 2, 14, 1, 'Link - Set Faction Hostile'),
(42386, 0, 2, 3, 62, 100, 11635, 1, 72, 0, 7, 'On Gossip Option 1 - Close Gossip'),
(42386, 0, 3, 0, 61, 100, 0, 0, 33, 42416, 7, 'Link - Give Kill Credit');

-- For 42391 (Clue 4 = 42417)
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_chance`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `target_type`, `comment`) VALUES
(42391, 0, 0, 1, 62, 100, 11635, 0, 72, 0, 7, 'On Gossip Option 0 - Close Gossip'),
(42391, 0, 1, 0, 61, 100, 0, 0, 2, 14, 1, 'Link - Set Faction Hostile'),
(42391, 0, 2, 3, 62, 100, 11635, 1, 72, 0, 7, 'On Gossip Option 1 - Close Gossip'),
(42391, 0, 3, 0, 61, 100, 0, 0, 33, 42417, 7, 'Link - Give Kill Credit');
