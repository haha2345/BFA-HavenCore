-- BFA-HavenCore

-- Darkshore: Unbound Fire Elemental (32999) - Rush of Flame fix

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 32999
  AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`,
 `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`,
 `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`,
 `target_x`, `target_y`, `target_z`, `target_o`,
 `comment`)
VALUES
-- 0: Flame Shock on a random timer in combat (unchanged, just re-inserted cleanly)
(32999, 0, 0, 0,
 0, 0, 100, 0,
 2000, 4500, 9000, 15000, 0,
 11, 13729, 0, 0, 0, 0, 0,
 2, 0, 0, 0, 0, 0, 0, 0,
 'Unbound Fire Elemental - Cast Flame Shock on victim'),

-- 1: Rush of Flame charge (75025) on victim - periodic combat timer
(32999, 0, 1, 2,
 0, 0, 100, 0,
 12000, 20000, 12000, 20000, 0,
 11, 75025, 0, 0, 0, 0, 0,
 2, 0, 0, 0, 0, 0, 0, 0,
 'Unbound Fire Elemental - Cast Rush of Flame (charge) on victim'),

-- 2: Rush of Flame trail (75024) cast on SELF immediately after 75025 fires.
(32999, 0, 2, 0,
 61, 0, 100, 0,
 0, 0, 0, 0, 0,
 11, 75024, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Unbound Fire Elemental - Cast Rush of Flame (fire trail) on self after charge'),

-- 3: On spell hit by 62430 - turn visible off (existing stealth behaviour, restored)
(32999, 0, 3, 0,
 8, 0, 100, 0,
 62430, 0, 0, 0, 0,
 47, 0, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Unbound Fire Elemental - On spellhit 62430 set visible off');
