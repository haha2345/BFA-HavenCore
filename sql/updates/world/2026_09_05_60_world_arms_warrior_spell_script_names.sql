-- 8.3.7.35662 Arms warrior: bind missing 8.3 scripts and fix Rallying Cry.
-- Do not edit DatabasesV1.1 dumps. Skip IDs already imported.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (260708, 29725, 50622, 845, 260643, 97462, 97463)
    AND `ScriptName` IN (
        'spell_warr_sweeping_strikes',
        'spell_warr_sudden_death',
        'spell_warr_bladestorm_periodic_damage',
        'spell_warr_cleave',
        'spell_warr_skullsplitter',
        'spell_warr_rallying_cry',
        'spell_warr_commanding_shout');

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (260708, 'spell_warr_sweeping_strikes'),
    (29725, 'spell_warr_sudden_death'),
    (50622, 'spell_warr_bladestorm_periodic_damage'),
    (845, 'spell_warr_cleave'),
    (260643, 'spell_warr_skullsplitter'),
    (97462, 'spell_warr_rallying_cry');
