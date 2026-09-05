-- 837 blizzlike: Haven private Freehold crew-week calendar (not 8.3 DBC). User confirmed 209/210/211 and brew 129009.

-- game_event.eventEntry is tinyint unsigned, so 209-211 can INSERT there.
-- game_event_creature.eventEntry dump is signed tinyint (-128..127) and already has
-- negative rows (e.g. -26 = unspawn during event). Cannot make it unsigned.
-- 209 > 127, so widen to smallint before binding creatures.

ALTER TABLE `game_event_creature`
  MODIFY `eventEntry` smallint NOT NULL COMMENT 'Entry of the game event. Put negative entry to remove during event.';

DELETE FROM `game_event` WHERE `eventEntry` IN (209, 210, 211);
INSERT INTO `game_event`
(`eventEntry`, `start_time`, `end_time`, `occurence`, `length`, `holiday`, `description`, `world_event`, `announce`)
VALUES
(209, '2018-08-14 00:00:00', '2035-12-31 23:59:59', 30240, 10080, 0, 'Haven private Freehold crew week: Cutwater Corsairs (破浪 / Jolly)', 0, 0),
(210, '2018-08-21 00:00:00', '2035-12-31 23:59:59', 30240, 10080, 0, 'Haven private Freehold crew week: Blacktooth Brawlers (黑齿 / Raoul)', 0, 0),
(211, '2018-08-28 00:00:00', '2035-12-31 23:59:59', 30240, 10080, 0, 'Haven private Freehold crew week: Bilge Rats (水鼠 / Eudora)', 0, 0);

-- Do not INSERT 280003427 (Rummy, file 10). Do not touch map 1643 outdoor 129009 rows.
-- Do not UPDATE creature_template for 129547 or 129009.
DELETE FROM `game_event_creature` WHERE `guid` IN (280003425, 280003426, 280003428, 280003429, 280003430);
DELETE FROM `creature` WHERE `guid` IN (280003425, 280003426, 280003428, 280003429, 280003430);

INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnDifficulties`, `phaseUseFlags`, `PhaseId`, `PhaseGroup`, `terrainSwapMap`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `unit_flags2`, `unit_flags3`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
	(280003425, 130467, 1754, 9164, 9639, '1,2,23,8', 0, 0, 0, -1, 0, 0, -1830.0, -470.0, 40.43, 5.45, 3600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'npc_freehold_murphy', 0),
	(280003426, 129441, 1754, 9164, 9639, '1,2,23,8', 0, 0, 0, -1, 0, 0, -1836.08, -466.288, 40.4451, 5.45, 3600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'npc_freehold_otis', 0),
	(280003428, 129547, 1754, 9164, 9164, '1,2,23,8', 0, 0, 0, -1, 0, 0, -1765.0, -720.0, 24.30, 0, 3600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'npc_freehold_crew_knuckleduster', 0),
	(280003429, 129547, 1754, 9164, 9164, '1,2,23,8', 0, 0, 0, -1, 0, 0, -1772.0, -718.0, 24.30, 0, 3600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'npc_freehold_crew_knuckleduster', 0),
	(280003430, 129009, 1754, 9164, 10039, '1,2,23,8', 0, 0, 0, -1, 0, 0, -1778.0, -690.0, 38.52, 3.15363, 3600, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 'npc_freehold_crew_brew', 0);

INSERT INTO `game_event_creature` (`eventEntry`, `guid`) VALUES
	(209, 280003425),
	(209, 280003426),
	(210, 280003428),
	(210, 280003429),
	(211, 280003430);
