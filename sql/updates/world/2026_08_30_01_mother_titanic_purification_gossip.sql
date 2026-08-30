-- Chamber of Heart MOTHER (152194): questgiver bit, Titanic Purification script, Curious Corruption turn-in.
-- Quest 58991 already exists (RewardSpell 317692). Do not INSERT a second quest_template.
-- SQL gossip_menu_option cannot open Blizzard_ItemInteractionUI; npc_mother_chamber_of_heart does.
-- Questgiver (2) is OR'd so vendor (128) and gossip (1) stay set.
-- 59000 Elements of Corruption also completes via credit 163275 from the same talk line.

UPDATE `creature_template`
SET `npcflag` = `npcflag` | 2,
    `ScriptName` = 'npc_mother_chamber_of_heart'
WHERE `entry` = 152194;

INSERT IGNORE INTO `creature_questender` (`id`, `quest`) VALUES
(152194, 58991),
(152194, 59000);
