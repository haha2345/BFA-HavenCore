-- Murloc Oracle (517)
DELETE FROM `smart_scripts` WHERE `entryorguid` = 517 AND `source_type` = 0;

INSERT INTO `smart_scripts` 
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param_string`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) 
VALUES 
    -- Cast Holy Smite (15498) on current victim (Cooldown: 4-7s)
    (517, 0, 0, 0, 0, 0, 100, 0, 1000, 3000, 4000, 7000, 0, '', 11, 15498, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 'Murloc Oracle - Cast Holy Smite on Victim'),

    -- Cast Power Word: Shield (17139) on Self @ <=50% HP (Cooldown: 25-30s)
    (517, 0, 1, 0, 2, 0, 100, 0, 0, 50, 25000, 30000, 0, '', 11, 17139, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Murloc Oracle - Cast PW:Shield on Self');