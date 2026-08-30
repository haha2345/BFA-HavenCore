-- Chamber of Heart MOTHER (creature_template.entry = 152194) preserved-contaminant shelf.
-- Controller-verified 2026-08-30: MAX(game_event.eventEntry) = 200, so this file uses 201-208 inclusive.
-- Do not hang vendors on 155923. Do not fill BonusListIDs. type=1 (ITEM_VENDOR_TYPE_ITEM); plan sample type=0 is wrong on this core.
-- Dual 4250 echoes: 6799 = 虹吸者一段 (17), 6800 = 闪避者三段 (16).
-- Dual 15000 echoes: 6810 = 无尽之星三段, 6793 = 暮光毁灭三段.
-- Rotations copy blizzard news 23453347 (see doc/837满级修复/细节-F5-玛乌尔商店.md). Each of 52 items is in exactly one window.
-- occurence/length are minutes. One window = 3.5 days = 5040. Full cycle = 8 windows = 40320.
-- start_time staggered from 2020-05-19 (retail contaminant vendor launch). end_time matches other events.

SET @NPC := 152194;
SET @CGUID := 210500001; -- free spawn guid; same guid in every game_event_npc_vendor row

-- game_event.eventEntry is tinyint unsigned (0-255). This table was signed tinyint
-- (-128..127), so 201-208 cannot insert under STRICT_TRANS_TABLES.
ALTER TABLE `game_event_npc_vendor`
  MODIFY `eventEntry` tinyint unsigned NOT NULL;

-- Gossip (1) + vendor (128) = 129. Must run before next-startup vendor validation.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 129 WHERE `entry` = @NPC;

-- Map 2215 (Chamber of Heart - Repaired), not UiMap 1473.
-- XY from AllTheThings 48.15, 72.54 via UiMapAssignment (1473, 2215) and Zone2MapCoordinates swap.
-- position_z = 0: ClientData/maps/2215_*.map and vmaps were not readable from the repo tree.
-- GM `.gps` on the Heart Forge floor must replace Z before this spawn is used live.
DELETE FROM `creature` WHERE `guid` = @CGUID;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnDifficulties`, `phaseUseFlags`, `PhaseId`, `PhaseGroup`, `terrainSwapMap`,
 `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `spawndist`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
 `npcflag`, `unit_flags`, `unit_flags2`, `unit_flags3`, `dynamicflags`, `ScriptName`, `VerifiedBuild`)
VALUES
(@CGUID, @NPC, 2215, 0, 0, '0', 0, 0, 0, -1,
 0, 0, 1762.40, -8377.61, 0, 0,
 300, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, '', 35662);

DELETE FROM `game_event_npc_vendor` WHERE `eventEntry` BETWEEN 201 AND 208;
DELETE FROM `game_event` WHERE `eventEntry` BETWEEN 201 AND 208;

INSERT INTO `game_event`
(`eventEntry`, `start_time`, `end_time`, `occurence`, `length`, `holiday`, `description`, `world_event`, `announce`)
VALUES
(201, '2020-05-19 00:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 1', 0, 0),
(202, '2020-05-22 12:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 2', 0, 0),
(203, '2020-05-26 00:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 3', 0, 0),
(204, '2020-05-29 12:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 4', 0, 0),
(205, '2020-06-02 00:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 5', 0, 0),
(206, '2020-06-05 12:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 6', 0, 0),
(207, '2020-06-09 00:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 7', 0, 0),
(208, '2020-06-12 12:00:00', '2030-12-31 17:00:00', 40320, 5040, 0, 'MOTHER Contaminants Rotation 8', 0, 0);

INSERT INTO `game_event_npc_vendor`
(`eventEntry`, `guid`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`, `BonusListIDs`, `PlayerConditionId`, `IgnoreFiltering`)
VALUES
-- Rotation 1: 真相 12, 磨砺心灵 15, 击穿 15, 娴熟 15, 附肢 66, 权宜之计 20
(201, @CGUID, 0, 177981, 0, 0, 6797, 1, '', 0, 0), -- 真相 1, 3300 echoes
(201, @CGUID, 1, 177978, 0, 0, 6798, 1, '', 0, 0), -- 磨砺心灵 1, 4125 echoes
(201, @CGUID, 2, 177999, 0, 0, 6798, 1, '', 0, 0), -- 击穿 2, 4125 echoes
(201, @CGUID, 3, 177987, 0, 0, 6798, 1, '', 0, 0), -- 娴熟 2, 4125 echoes
(201, @CGUID, 4, 178009, 0, 0, 6809, 1, '', 0, 0), -- 附肢 3, 13200 echoes
(201, @CGUID, 5, 177975, 0, 0, 6801, 1, '', 0, 0), -- 权宜之计 3, 5000 echoes
-- Rotation 2: 虚空仪式 15, 娴熟 10, 虹吸者 28, 致命之势 20, 真相 30, 多才多艺 20, 闪避者 12
(202, @CGUID, 0, 178013, 0, 0, 6798, 1, '', 0, 0), -- 虚空仪式 1, 4125 echoes
(202, @CGUID, 1, 177986, 0, 0, 6796, 1, '', 0, 0), -- 娴熟 1, 3000 echoes
(202, @CGUID, 2, 177996, 0, 0, 6803, 1, '', 0, 0), -- 虹吸者 2, 6300 echoes
(202, @CGUID, 3, 177965, 0, 0, 6801, 1, '', 0, 0), -- 致命之势 2, 5000 echoes
(202, @CGUID, 4, 177982, 0, 0, 6804, 1, '', 0, 0), -- 真相 2, 6750 echoes
(202, @CGUID, 5, 178012, 0, 0, 6801, 1, '', 0, 0), -- 多才多艺 3, 5000 echoes
(202, @CGUID, 6, 177971, 0, 0, 6797, 1, '', 0, 0), -- 闪避者 2, 3300 echoes
-- Rotation 3: 无尽之星 20, 活力涌动 15, 须臾洞察 15, 暴戾 15, 虹吸者 45, 急速脉搏 35, 闪避者 16
(203, @CGUID, 0, 177983, 0, 0, 6801, 1, '', 0, 0), -- 无尽之星 1, 5000 echoes
(203, @CGUID, 1, 178001, 0, 0, 6798, 1, '', 0, 0), -- 活力涌动 1, 4125 echoes
(203, @CGUID, 2, 177976, 0, 0, 6798, 1, '', 0, 0), -- 须臾洞察, 4125 echoes
(203, @CGUID, 3, 177993, 0, 0, 6798, 1, '', 0, 0), -- 暴戾 2, 4125 echoes
(203, @CGUID, 4, 177997, 0, 0, 6806, 1, '', 0, 0), -- 虹吸者 3, 9000 echoes
(203, @CGUID, 5, 177991, 0, 0, 6805, 1, '', 0, 0), -- 急速脉搏 3, 7875 echoes
(203, @CGUID, 6, 177972, 0, 0, 6800, 1, '', 0, 0), -- 闪避者 3, 4250 echoes (6800 not 6799)
-- Rotation 4: 虹吸者 17, 暴戾 10, 暮光毁灭 50, 权宜之计 15, 击穿 20, 磨砺心灵 35
(204, @CGUID, 0, 177995, 0, 0, 6799, 1, '', 0, 0), -- 虹吸者 1, 4250 echoes (6799 not 6800)
(204, @CGUID, 1, 177992, 0, 0, 6796, 1, '', 0, 0), -- 暴戾 1, 3000 echoes
(204, @CGUID, 2, 178005, 0, 0, 6807, 1, '', 0, 0), -- 暮光毁灭 2, 10000 echoes
(204, @CGUID, 3, 177974, 0, 0, 6798, 1, '', 0, 0), -- 权宜之计 2, 4125 echoes
(204, @CGUID, 4, 178000, 0, 0, 6801, 1, '', 0, 0), -- 击穿 3, 5000 echoes
(204, @CGUID, 5, 177980, 0, 0, 6805, 1, '', 0, 0), -- 磨砺心灵 3, 7875 echoes
-- Rotation 5: 附肢 10, 权宜之计 10, 虚空回响 35, 急速脉搏 20, 无尽之星 75, 暴戾 20
(205, @CGUID, 0, 178007, 0, 0, 6796, 1, '', 0, 0), -- 附肢 1, 3000 echoes
(205, @CGUID, 1, 177973, 0, 0, 6796, 1, '', 0, 0), -- 权宜之计 1, 3000 echoes
(205, @CGUID, 2, 177968, 0, 0, 6805, 1, '', 0, 0), -- 虚空回响 2, 7875 echoes
(205, @CGUID, 3, 177990, 0, 0, 6801, 1, '', 0, 0), -- 急速脉搏 2, 5000 echoes
(205, @CGUID, 4, 177985, 0, 0, 6810, 1, '', 0, 0), -- 无尽之星 3, 15000 echoes (6810 not 6793)
(205, @CGUID, 5, 177994, 0, 0, 6801, 1, '', 0, 0), -- 暴戾 3, 5000 echoes
-- Rotation 6: 击穿 10, 急速脉搏 15, 虚空仪式 35, 活力涌动 20, 暮光毁灭 75, 娴熟 20, 闪避者 8
(206, @CGUID, 0, 177998, 0, 0, 6796, 1, '', 0, 0), -- 击穿 1, 3000 echoes
(206, @CGUID, 1, 177989, 0, 0, 6798, 1, '', 0, 0), -- 急速脉搏 1, 4125 echoes
(206, @CGUID, 2, 178014, 0, 0, 6805, 1, '', 0, 0), -- 虚空仪式 2, 7875 echoes
(206, @CGUID, 3, 178002, 0, 0, 6801, 1, '', 0, 0), -- 活力涌动 2, 5000 echoes
(206, @CGUID, 4, 178006, 0, 0, 6793, 1, '', 0, 0), -- 暮光毁灭 3, 15000 echoes (6793 not 6810)
(206, @CGUID, 5, 177988, 0, 0, 6801, 1, '', 0, 0), -- 娴熟 3, 5000 echoes
(206, @CGUID, 6, 177970, 0, 0, 6795, 1, '', 0, 0), -- 闪避者 1, 2400 echoes
-- Rotation 7: 虚空回响 25, 多才多艺 10, 无尽之星 50, 磨砺心灵 20, 虚空仪式 66, 致命之势 35, 龟裂创伤 15
(207, @CGUID, 0, 177969, 0, 0, 6802, 1, '', 0, 0), -- 虚空回响 1, 6250 echoes
(207, @CGUID, 1, 178010, 0, 0, 6796, 1, '', 0, 0), -- 多才多艺 1, 3000 echoes
(207, @CGUID, 2, 177984, 0, 0, 6807, 1, '', 0, 0), -- 无尽之星 2, 10000 echoes
(207, @CGUID, 3, 177979, 0, 0, 6801, 1, '', 0, 0), -- 磨砺心灵 2, 5000 echoes
(207, @CGUID, 4, 178015, 0, 0, 6809, 1, '', 0, 0), -- 虚空仪式 3, 13200 echoes
(207, @CGUID, 5, 177966, 0, 0, 6805, 1, '', 0, 0), -- 致命之势 3, 7875 echoes
(207, @CGUID, 6, 177977, 0, 0, 6798, 1, '', 0, 0), -- 龟裂创伤, 4125 echoes
-- Rotation 8: 暮光毁灭 25, 致命之势 15, 附肢 35, 多才多艺 15, 虚空回响 60, 活力涌动 35
(208, @CGUID, 0, 178004, 0, 0, 6802, 1, '', 0, 0), -- 暮光毁灭 1, 6250 echoes
(208, @CGUID, 1, 177955, 0, 0, 6798, 1, '', 0, 0), -- 致命之势 1, 4125 echoes
(208, @CGUID, 2, 178008, 0, 0, 6805, 1, '', 0, 0), -- 附肢 2, 7875 echoes
(208, @CGUID, 3, 178011, 0, 0, 6798, 1, '', 0, 0), -- 多才多艺 2, 4125 echoes
(208, @CGUID, 4, 177967, 0, 0, 6808, 1, '', 0, 0), -- 虚空回响 3, 12000 echoes
(208, @CGUID, 5, 178003, 0, 0, 6805, 1, '', 0, 0); -- 活力涌动 3, 7875 echoes
