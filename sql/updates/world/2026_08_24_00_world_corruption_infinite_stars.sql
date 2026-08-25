-- 837 blizzlike: Infinite Stars (腐蚀 - 无尽之星) spell scripts
-- 35662 IDs from in-game lookup + Spell.db2. Wrapper 324889-91, hidden proc 317257,
-- selector 317260, missile 317262, damage/stack 317265.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (324889, 324890, 324891, 317257, 317260, 317265);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(324889, 'spell_corruption_infinite_stars'),
(324890, 'spell_corruption_infinite_stars'),
(324891, 'spell_corruption_infinite_stars'),
(317257, 'spell_infinite_stars_proc'),
(317260, 'spell_infinite_stars_selector'),
(317265, 'spell_infinite_stars_damage');
