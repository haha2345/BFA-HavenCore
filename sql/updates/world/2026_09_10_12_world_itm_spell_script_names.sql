-- 837 blizzlike: ITM 签名饰品。珊瑚 Dummy 0 是 ON_USE 钩子，不是 ppm 6。
-- 303564 Dummy 0（Effect=3）。RangeIndex 5=40.0 码不是 Dummy。CD 20000/20000 走表。
-- 303565 Dummy 0。ppm copy 167<-124，id 124 rate=6.0 是 35662 表。6 不进 Dummy 0。不要写 6.0f。
-- 303573 Dummy 0 + Coef 0.26542931795 不是 Dummy。304877 Dummy 0 + Coef 22.99152565002 不是 Dummy。
-- 303568 Dummy 0。303570 / 303572 无 Dummy。禁止 INSERT 303572/303570/303568/303573/304877。
-- 313948 Dummy 8/5/0。Coef 2.75913739204 不是 Dummy。Dummy 8 是百分不是码。Dummy 5 是人数上限不是码。
-- 314040 Dummy 0 + Coef 0.55182754993 不是 Dummy。314042 Dummy 1，1 不得改成码。
-- 禁止 INSERT 277253/303572/303570/303568/303573/304877/173944/313148/313194/302855。
-- 禁止 DELETE 277253 spell_item_heart_of_azeroth。
-- 禁止占用 2026_09_10_09～_11（AZ）、_06～_08（RAC）、_02～_05（MAS）、_00/_01（PET）。
DELETE FROM `spell_script_names` WHERE `spell_id` = 303564 AND `ScriptName` = 'spell_item_ashvanes_razor_coral';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (303564, 'spell_item_ashvanes_razor_coral');
DELETE FROM `spell_script_names` WHERE `spell_id` = 303565 AND `ScriptName` = 'spell_item_ashvanes_razor_coral_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (303565, 'spell_item_ashvanes_razor_coral_proc');
DELETE FROM `spell_script_names` WHERE `spell_id` = 313948 AND `ScriptName` = 'spell_item_manifesto_of_madness';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (313948, 'spell_item_manifesto_of_madness');
DELETE FROM `spell_script_names` WHERE `spell_id` = 314040 AND `ScriptName` = 'spell_item_manifesto_of_madness_chapter_two';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (314040, 'spell_item_manifesto_of_madness_chapter_two');
DELETE FROM `spell_script_names` WHERE `spell_id` = 314042 AND `ScriptName` = 'spell_item_manifesto_of_madness_equip';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (314042, 'spell_item_manifesto_of_madness_equip');
