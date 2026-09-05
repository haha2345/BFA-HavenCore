-- 837 blizzlike: Waycrest Manor 131818 missing Runic Mark 264105 on all difficulties; timer copied from 131666 id 0 / 131812 id 1, not DBC.

DELETE FROM `smart_scripts` WHERE `entryorguid`=131818 AND `source_type`=0 AND `id`=1 AND `link`=0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param_string`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(131818, 0, 1, 0, 0, 0, 100, 0,
 3000, 5000, 12000, 15000, 0, '',
 11, 264105, 0, 0, 0, 0, 0,
 5, 0, 1, 0, 0, 0, 0, 0,
 'Cast Runic Mark on random hostile player (interval from 131666 id 0 / 131812 id 1, not DBC; all difficulties)');
