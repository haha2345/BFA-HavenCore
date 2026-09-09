-- 837 blizzlike: DRU-Feral 接线原始愤怒、愈合触发血爪、掠食者的迅捷终结技。77493 不搬家。145152 不 INSERT 空壳。
-- 禁止 INSERT 77493/210722/145152/5185/323764 空壳。禁止 SetMaxStack 写进 SQL。
-- 禁止 DELETE 5221/1822/1079/22568/155672/16974/274837/106785/106830。禁止 DELETE 16974。
-- Dummy 0 在 155672。禁止三连。半径 8 不是 10。掠食 Dummy 20×消耗连击点。50/80 残留不读。
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(285381, 'spell_dru_primal_wrath'),
(8936, 'spell_dru_bloodtalons'),
(22568, 'spell_dru_predatory_swiftness'),
(1079, 'spell_dru_predatory_swiftness'),
(22570, 'spell_dru_predatory_swiftness');
