-- 837 blizzlike: SHA-Enh 接线 192106 闪电之盾与 262395 增强图腾掌握。
-- 禁止 INSERT 77223/204945/195255/Ice Strike/108287 空壳。
-- 禁止 DELETE 17364/60103/187874/51533/193796/196834/33757/187880/201845/210643。
-- 禁止发明 12 秒熔岩猛击。禁止把 25 写进 33757 Dummy 0。
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(192106, 'spell_sha_lightning_shield'),
(262395, 'spell_sha_totem_mastery');
