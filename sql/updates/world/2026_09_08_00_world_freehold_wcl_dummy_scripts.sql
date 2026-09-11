-- 837 blizzlike: Dummy 265088/264608/265168 and 274383 do nothing without scripts; bind soak/root so heroic council brew and trapper traps play like a normal dungeon.

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_freehold_rummy_brew', 'spell_freehold_rat_traps');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(265088, 'spell_freehold_rummy_brew'),
(264608, 'spell_freehold_rummy_brew'),
(265168, 'spell_freehold_rummy_brew'),
(274383, 'spell_freehold_rat_traps');
