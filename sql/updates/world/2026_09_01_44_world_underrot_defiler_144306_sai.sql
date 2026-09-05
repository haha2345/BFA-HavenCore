-- 837 blizzlike: Underrot summon-group 144306 had zero SAI; give same three spells/timers as static 133912. Not a merge of two entries. Timers are dump copies, not DBC.

DELETE FROM `smart_scripts` WHERE `entryorguid`=144306 AND `source_type`=0;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param_string`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(144306, 0, 0, 0, 0, 0, 100, 0,
 5000, 8000, 25000, 37000, 0, '',
 11, 265523, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Cast Summon Spirit Drain Totem (timers copied from 133912 id 0, not DBC; not a guid merge)'),
(144306, 0, 1, 0, 0, 0, 100, 0,
 3000, 5000, 12000, 15000, 0, '',
 11, 265433, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Cast Withering Curse (timers copied from 133912 id 1, not DBC; not a guid merge)'),
(144306, 0, 2, 0, 0, 0, 100, 0,
 0, 0, 3000, 3500, 0, '',
 11, 265487, 64, 0, 0, 0, 0,
 2, 0, 0, 0, 0, 0, 0, 0,
 'Cast Shadow Bolt Volley (timers copied from 133912 id 2, not DBC; not a guid merge)');
