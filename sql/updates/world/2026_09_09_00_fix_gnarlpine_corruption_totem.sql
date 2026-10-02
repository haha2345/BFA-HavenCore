-- BFA-HavenCore
-- Fixes: https://github.com/HavenWoW/BFA-HavenCore/issues/242

UPDATE `creature_template`
SET `unit_flags` = 768  -- UNIT_FLAG_IMMUNE_TO_PC (256) | UNIT_FLAG_IMMUNE_TO_NPC (512)
WHERE `entry` = 49598;
