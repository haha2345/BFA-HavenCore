-- Bind only the three map 2097 static guids. Do not change creature_template,
-- spawn coordinates, entry, or guid. A second run changes 0 rows.
-- SAI rows are removed only when no other creature of that entry exists,
-- so a copy on another map keeps its SmartAI cast.

UPDATE `creature`
SET `ScriptName` = 'npc_mechagon_squirt_bot'
WHERE `guid` IN (3300000000000910, 3300000000000911, 3300000000000912)
  AND `id` IN (154741, 154746, 154759)
  AND `map` = 2097
  AND `ScriptName` <> 'npc_mechagon_squirt_bot';

DELETE s FROM `smart_scripts` s
WHERE s.`source_type` = 0
  AND s.`entryorguid` IN (154741, 154746, 154759)
  AND s.`id` = 0
  AND s.`link` = 0
  AND s.`event_type` = 0
  AND s.`event_phase_mask` = 0
  AND s.`event_chance` = 100
  AND s.`event_flags` = 0
  AND s.`event_param1` = 3000
  AND s.`event_param2` = 5000
  AND s.`event_param3` = 12000
  AND s.`event_param4` = 15000
  AND s.`event_param5` = 0
  AND s.`action_type` = 11
  AND s.`action_param1` = 297901
  AND s.`action_param2` = 0
  AND s.`action_param3` = 0
  AND s.`action_param4` = 0
  AND s.`action_param5` = 0
  AND s.`action_param6` = 0
  AND s.`target_type` = 1
  AND s.`target_param1` = 0
  AND s.`target_param2` = 0
  AND s.`target_param3` = 0
  AND NOT EXISTS (
      SELECT 1 FROM `creature` c
      WHERE c.`id` = s.`entryorguid`
        AND c.`guid` NOT IN (3300000000000910, 3300000000000911, 3300000000000912)
  );
