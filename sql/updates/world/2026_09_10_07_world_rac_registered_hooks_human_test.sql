-- 837 blizzlike: RAC 已注册钩子核对。禁止再改 spell_generic.cpp。
-- 257040 Dummy 0 传送钩子，不要编伤。256948 学会号无 Dummy，DurationIndex 32=6秒（裂隙，不是 260369）。
-- 274738 Dummy 0 抽签。1.32 走子号 274739-274742，不是 Dummy 基点。
-- 255652 PlayerScript 不走 spell_script_names。256896 Coef 352.53 不是 Dummy。
-- 20577 Dummy 0 -> 20578 BP 7 不是 Dummy。
-- 禁止 INSERT 256948/257034/255652/256896/274739/274740/274741/274742/20578。
-- 禁止 DELETE 257040/274738/20577。
-- 本文件无 INSERT / DELETE。人测走 rac_voidelf_spatial_rift_dummy0 等。
SELECT spell_id, ScriptName
FROM spell_script_names
WHERE spell_id IN (257040, 274738, 20577, 256948, 255652);
