-- 837 blizzlike: RAC 走表不包空。经典狂暴/血性狂怒无 Dummy、3307 无独立脚本。
-- 禁止 INSERT 26297/20572/33697/33702/20549/20573/20594/69041/255654/291944。
-- 禁止 INSERT 语言/专业/坐骑/炉石/营地当本波验收。
-- 禁止 DELETE 312370/312372（营地登记不验收）。
-- 禁止 DELETE 206150 spell_challengers_might（词缀不进 RAC，也不准拆掉）。
-- 禁止把 70733 spell_icc_stoneform / 106951 spell_dru_berserk 当成种族石化/狂暴。
-- 291944 Dummy 100 是 tooltip；Aura 20 BP 16.5 不是 Dummy。
-- 本文件无 INSERT / DELETE。人测走 rac_troll_berserking_table_only 等。
SELECT spell_id, ScriptName
FROM spell_script_names
WHERE spell_id IN (26297, 20572, 33697, 33702, 20549, 291944, 255654, 312370, 312372, 206150, 70733, 106951);
