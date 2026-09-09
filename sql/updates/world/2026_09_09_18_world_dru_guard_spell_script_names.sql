-- 837 blizzlike: DRU-Guard 接线熊横扫/鬃毛倒竖/铁鬃。155783/33917 不 INSERT 空壳。
-- 禁止 INSERT 155783/33917/22842/77484 空壳。
-- 必须 INSERT (192081, 'spell_dru_ironfur')。禁止「不 INSERT 192081」。
-- 禁止 DELETE 77758/192090/6807/210706/22842/61336/22812/80313/203964。
-- 狂暴回复 6%/3 秒不是 50%/5 秒。铁鬃 75 不是 Dummy。Gore Dummy 15。0.605 不得进 Dummy。
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(213771, 'spell_dru_swipe_bear'),
(155835, 'spell_dru_bristling_fur'),
(192081, 'spell_dru_ironfur');
