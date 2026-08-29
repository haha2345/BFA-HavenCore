-- 837 blizzlike: Whispered Truths (Whispering Eldritch Bow).
-- Auto-shot trims one hunter class cooldown currently ticking. Do NOT write spell_proc.

DELETE FROM `spell_script_names` WHERE `spell_id` = 316780;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(316780, 'spell_whispered_truths');
