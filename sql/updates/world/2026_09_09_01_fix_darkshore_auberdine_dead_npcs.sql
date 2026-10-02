-- BFA-HavenCore

UPDATE `creature_template`
SET `unit_flags` = 33024  -- UNIT_FLAG_IMMUNE_TO_PC (0x100) | UNIT_FLAG_NON_ATTACKABLE_2 (0x8000)
WHERE `entry` IN (33001, 33033, 33035, 33037);

UPDATE `creature_template`
SET `unit_flags` = 33554688  -- NOT_SELECTABLE (0x2000000) | IMMUNE_TO_PC (0x100) | NON_ATTACKABLE_2 (0x8000)
WHERE `entry` = 33039;

UPDATE `creature_template`
SET `unit_flags` = 33555712  -- NOT_SELECTABLE (0x2000000) | IMMUNE_TO_PC (0x100) | IMMUNE_TO_NPC (0x200) | NON_ATTACKABLE_2 (0x8000)
WHERE `entry` = 33040;

UPDATE `creature_template_addon`
SET `bytes1` = 7  -- UNIT_STAND_STATE_DEAD
WHERE `entry` IN (33001, 33033, 33035, 33037, 33039, 33040);

UPDATE `creature_template`
SET `dynamicflags` = 4  -- UNIT_DYNFLAG_DEAD
WHERE `entry` IN (33001, 33033, 33035, 33037, 33039, 33040);
