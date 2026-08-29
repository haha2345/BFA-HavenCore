-- 837 blizzlike: Eye of Corruption pulse (315161) fills Wowhead 2020 measured
-- damage; Grand Delusions contact uses 315197 (35% max HP) from SpellEffect.
-- Do not bind cloak extra 313301.

DELETE FROM `spell_script_names` WHERE `spell_id` = 315161 AND `ScriptName` = 'spell_eye_of_corruption_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(315161, 'spell_eye_of_corruption_damage');
