-- 837 blizzlike: linked hidden 405 (Expedient/Masterful/Versatile/Severe)
-- sum Dummy 6/9/12 per worn rank. Append rank_driver; do not wipe 2026_08_27_16.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (320257, 320253, 320259, 320261)
    AND `ScriptName` IN (
        'spell_corruption_expedient_hidden',
        'spell_corruption_masterful_hidden',
        'spell_corruption_versatile_hidden',
        'spell_corruption_severe_hidden');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(320257, 'spell_corruption_expedient_hidden'),
(320253, 'spell_corruption_masterful_hidden'),
(320259, 'spell_corruption_versatile_hidden'),
(320261, 'spell_corruption_severe_hidden');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (
    315544, 315545, 315546,
    315529, 315530, 315531,
    315549, 315552, 315553,
    315554, 315557, 315558)
    AND `ScriptName` = 'spell_corruption_rank_driver';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(315544, 'spell_corruption_rank_driver'),
(315545, 'spell_corruption_rank_driver'),
(315546, 'spell_corruption_rank_driver'),
(315529, 'spell_corruption_rank_driver'),
(315530, 'spell_corruption_rank_driver'),
(315531, 'spell_corruption_rank_driver'),
(315549, 'spell_corruption_rank_driver'),
(315552, 'spell_corruption_rank_driver'),
(315553, 'spell_corruption_rank_driver'),
(315554, 'spell_corruption_rank_driver'),
(315557, 'spell_corruption_rank_driver'),
(315558, 'spell_corruption_rank_driver');
