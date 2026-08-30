-- Chamber of Heart MOTHER: Chinese greeting, vendor shelf order by effect then rank.
-- Gossip options are in npc_mother_chamber_of_heart.cpp. Body text is BroadcastText 201785 (hotfix).
-- creature_template_locale.zhCN is already 纯净圣母; default name follows that.

SET @NPC := 152194;
SET @MENU := 152194;
SET @TEXT := 900001;
SET @BTEXT := 201785;
SET @CGUID := 210500001;

UPDATE `creature_template`
SET `name` = '纯净圣母',
    `gossip_menu_id` = @MENU
WHERE `entry` = @NPC;

INSERT IGNORE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `VerifiedBuild`)
VALUES (@NPC, 'zhCN', '纯净圣母', 35662);
UPDATE `creature_template_locale`
SET `Name` = '纯净圣母'
WHERE `entry` = @NPC AND `locale` = 'zhCN';

DELETE FROM `npc_text` WHERE `ID` = @TEXT;
INSERT INTO `npc_text`
(`ID`, `Probability0`, `Probability1`, `Probability2`, `Probability3`, `Probability4`, `Probability5`, `Probability6`, `Probability7`,
 `BroadcastTextID0`, `BroadcastTextID1`, `BroadcastTextID2`, `BroadcastTextID3`, `BroadcastTextID4`, `BroadcastTextID5`, `BroadcastTextID6`, `BroadcastTextID7`, `VerifiedBuild`)
VALUES
(@TEXT, 1, 0, 0, 0, 0, 0, 0, 0, @BTEXT, 0, 0, 0, 0, 0, 0, 0, 35662);

DELETE FROM `gossip_menu` WHERE `MenuId` = @MENU;
INSERT INTO `gossip_menu` (`MenuId`, `TextId`, `VerifiedBuild`)
VALUES (@MENU, @TEXT, 35662);

-- Re-slot each rotation so Mode=0 windows follow the same family-then-rank order as QA Mode=1.
DELETE FROM `game_event_npc_vendor` WHERE `eventEntry` BETWEEN 201 AND 208;
INSERT INTO `game_event_npc_vendor`
(`eventEntry`, `guid`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`, `BonusListIDs`, `PlayerConditionId`, `IgnoreFiltering`)
VALUES
-- Rotation 1 (same family-then-rank key as QA mode)
(201, @CGUID, 0, 177975, 0, 0, 6801, 1, '', 0, 0), -- 权宜之计 三段
(201, @CGUID, 1, 177978, 0, 0, 6798, 1, '', 0, 0), -- 磨砺心灵 一段
(201, @CGUID, 2, 177981, 0, 0, 6797, 1, '', 0, 0), -- 不可言喻的真相 一段
(201, @CGUID, 3, 177987, 0, 0, 6798, 1, '', 0, 0), -- 娴熟 二段
(201, @CGUID, 4, 177999, 0, 0, 6798, 1, '', 0, 0), -- 击穿 二段
(201, @CGUID, 5, 178009, 0, 0, 6809, 1, '', 0, 0), -- 扭曲的附肢 三段
-- Rotation 2
(202, @CGUID, 0, 177965, 0, 0, 6801, 1, '', 0, 0), -- 致命之势 二段
(202, @CGUID, 1, 177971, 0, 0, 6797, 1, '', 0, 0), -- 闪避者 二段
(202, @CGUID, 2, 177982, 0, 0, 6804, 1, '', 0, 0), -- 不可言喻的真相 二段
(202, @CGUID, 3, 177986, 0, 0, 6796, 1, '', 0, 0), -- 娴熟 一段
(202, @CGUID, 4, 177996, 0, 0, 6803, 1, '', 0, 0), -- 虹吸者 二段
(202, @CGUID, 5, 178012, 0, 0, 6801, 1, '', 0, 0), -- 多才多艺 三段
(202, @CGUID, 6, 178013, 0, 0, 6798, 1, '', 0, 0), -- 虚空仪式 一段
-- Rotation 3
(203, @CGUID, 0, 177972, 0, 0, 6800, 1, '', 0, 0), -- 闪避者 三段
(203, @CGUID, 1, 177976, 0, 0, 6798, 1, '', 0, 0), -- 须臾洞察 一段
(203, @CGUID, 2, 177983, 0, 0, 6801, 1, '', 0, 0), -- 无尽之星 一段
(203, @CGUID, 3, 177991, 0, 0, 6805, 1, '', 0, 0), -- 急速脉搏 三段
(203, @CGUID, 4, 177993, 0, 0, 6798, 1, '', 0, 0), -- 暴戾 二段
(203, @CGUID, 5, 177997, 0, 0, 6806, 1, '', 0, 0), -- 虹吸者 三段
(203, @CGUID, 6, 178001, 0, 0, 6798, 1, '', 0, 0), -- 活力涌动 一段
-- Rotation 4
(204, @CGUID, 0, 177974, 0, 0, 6798, 1, '', 0, 0), -- 权宜之计 二段
(204, @CGUID, 1, 177980, 0, 0, 6805, 1, '', 0, 0), -- 磨砺心灵 三段
(204, @CGUID, 2, 177992, 0, 0, 6796, 1, '', 0, 0), -- 暴戾 一段
(204, @CGUID, 3, 177995, 0, 0, 6799, 1, '', 0, 0), -- 虹吸者 一段
(204, @CGUID, 4, 178000, 0, 0, 6801, 1, '', 0, 0), -- 击穿 三段
(204, @CGUID, 5, 178005, 0, 0, 6807, 1, '', 0, 0), -- 暮光毁灭 二段
-- Rotation 5
(205, @CGUID, 0, 177968, 0, 0, 6805, 1, '', 0, 0), -- 虚空回响 二段
(205, @CGUID, 1, 177973, 0, 0, 6796, 1, '', 0, 0), -- 权宜之计 一段
(205, @CGUID, 2, 177985, 0, 0, 6810, 1, '', 0, 0), -- 无尽之星 三段
(205, @CGUID, 3, 177990, 0, 0, 6801, 1, '', 0, 0), -- 急速脉搏 二段
(205, @CGUID, 4, 177994, 0, 0, 6801, 1, '', 0, 0), -- 暴戾 三段
(205, @CGUID, 5, 178007, 0, 0, 6796, 1, '', 0, 0), -- 扭曲的附肢 一段
-- Rotation 6
(206, @CGUID, 0, 177970, 0, 0, 6795, 1, '', 0, 0), -- 闪避者 一段
(206, @CGUID, 1, 177988, 0, 0, 6801, 1, '', 0, 0), -- 娴熟 三段
(206, @CGUID, 2, 177989, 0, 0, 6798, 1, '', 0, 0), -- 急速脉搏 一段
(206, @CGUID, 3, 177998, 0, 0, 6796, 1, '', 0, 0), -- 击穿 一段
(206, @CGUID, 4, 178002, 0, 0, 6801, 1, '', 0, 0), -- 活力涌动 二段
(206, @CGUID, 5, 178006, 0, 0, 6793, 1, '', 0, 0), -- 暮光毁灭 三段
(206, @CGUID, 6, 178014, 0, 0, 6805, 1, '', 0, 0), -- 虚空仪式 二段
-- Rotation 7
(207, @CGUID, 0, 177966, 0, 0, 6805, 1, '', 0, 0), -- 致命之势 三段
(207, @CGUID, 1, 177969, 0, 0, 6802, 1, '', 0, 0), -- 虚空回响 一段
(207, @CGUID, 2, 177977, 0, 0, 6798, 1, '', 0, 0), -- 龟裂创伤 一段
(207, @CGUID, 3, 177979, 0, 0, 6801, 1, '', 0, 0), -- 磨砺心灵 二段
(207, @CGUID, 4, 177984, 0, 0, 6807, 1, '', 0, 0), -- 无尽之星 二段
(207, @CGUID, 5, 178010, 0, 0, 6796, 1, '', 0, 0), -- 多才多艺 一段
(207, @CGUID, 6, 178015, 0, 0, 6809, 1, '', 0, 0), -- 虚空仪式 三段
-- Rotation 8
(208, @CGUID, 0, 177955, 0, 0, 6798, 1, '', 0, 0), -- 致命之势 一段
(208, @CGUID, 1, 177967, 0, 0, 6808, 1, '', 0, 0), -- 虚空回响 三段
(208, @CGUID, 2, 178003, 0, 0, 6805, 1, '', 0, 0), -- 活力涌动 三段
(208, @CGUID, 3, 178004, 0, 0, 6802, 1, '', 0, 0), -- 暮光毁灭 一段
(208, @CGUID, 4, 178008, 0, 0, 6805, 1, '', 0, 0), -- 扭曲的附肢 二段
(208, @CGUID, 5, 178011, 0, 0, 6798, 1, '', 0, 0); -- 多才多艺 二段
