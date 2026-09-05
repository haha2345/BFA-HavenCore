-- 837 blizzlike: Temple of Sethraliss 134600 missing Neurotoxin 273563 on all difficulties; timer copied from existing id 0, not DBC.

DELETE FROM `smart_scripts` WHERE `entryorguid`=134600 AND `source_type`=0 AND `id`=3 AND `link`=0;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param_string`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(134600, 0, 3, 0, 0, 0, 100, 0,
 3000, 5000, 12000, 15000, 0, '',
 11, 273563, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Cast Neurotoxin on self as SRC_CASTER area (interval from id 0, not DBC; all difficulties)');
