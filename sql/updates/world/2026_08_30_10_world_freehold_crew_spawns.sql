-- 837 blizzlike: Place the only 1754 Rummy Mancomb (133219) at the council bar; weekly crew-event NPCs wait on dump/user week IDs.

-- Dump search 2026-08-30, read-only DatabasesV1.1/bfa_world/bfa_world.sql:
--   game_event.description: no Freehold / Cutwater / Blacktooth / Bilge / Crew / 自由镇 / 破浪 / 黑齿 / 水鼠 / 朗姆 week rows
--     (table runs 1-121 plus 200 Morph Event; no crew-week descriptions).
--   holiday / holiday_dates / worldstate / worldstates: tables not present in this dump.
--   game_event_creature: no guid in the 280003xxx range (all map 1754 creatures are 280003000-280003424).
--   game_event_gameobject: no 210409xxx rows (1754 cage 278291 guid 210409006 is unbound).
--   281357 / 130467 / 129441 / 129009 / 133219: no gossip_menu_option, npc_spellclick_spells, or smart_scripts
--     that apply 281357 as the dungeon brew event. 129009 is Vulpera Mixologist on outdoor map 1643, not a closed 8.3 brew entry.
-- Therefore this file does not INSERT game_event rows and does not INSERT Murphy / Otis / event knuckledusters / brew NPC
-- (guid 280003425 / 426 / 428 / 429 / 430). Wait for the user to confirm week table+IDs and the brew NPC entry, then add those rows.

INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnDifficulties`, `phaseUseFlags`, `PhaseId`, `PhaseGroup`, `terrainSwapMap`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `unit_flags2`, `unit_flags3`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
	(280003427, 133219, 1754, 9164, 10039, '1,2,23,8', 0, 0, 0, -1, 0, 0, -1780.0, -678.0, 38.52, 3.15363, 3600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);
