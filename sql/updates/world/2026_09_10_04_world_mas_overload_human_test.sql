-- 837 blizzlike: MAS 过载验收。168534 Dummy 0/85/75。家在 spell_shaman.cpp，不搬家。
-- 现行读 EFFECT_0 GetAmount() + EFFECT_1 Dummy 85。不读 EFFECT_2 Dummy 75。全文无 roll_chance_f(15)。
-- 禁止再改 spell_shaman.cpp。禁止写回 15。禁止按分类旧句覆盖 Dummy 0。
-- 15 / 25 / 1.875 不得进 Dummy。禁止 INSERT 168534 到 spell_mastery_*。
-- 本文件无 INSERT / DELETE。人测走 mas_sha_overload_keep_shaman_file。
SELECT spell_id, ScriptName FROM spell_script_names WHERE spell_id = 168534;
