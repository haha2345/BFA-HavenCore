-- 837 blizzlike: AZ 地震波人测。禁止再改 spell_azerite.cpp / loader。
-- 277639 Dummy 10 是线宽码，Aura 285 Coef 9.52 不是 Dummy，Trigger 278495 由核心 HandleAuraLinked 挂。
-- 脚本禁止再 Cast 278495。278497 Dummy 0；Rad1=13=10.0 码不是 Dummy。
-- Dummy 10 不得改成 9.52。9.52 / 740 / 10 码不得进 Dummy 0。
-- 压制 7384 触发。不要改 spell_warrior.cpp。横扫第二波不验收。
-- 禁止 INSERT 277639/278506/7384。禁止 DELETE 278495/278497/277253。
-- 本文件无 INSERT / DELETE。人测走 az_seismic_wave_dummy10。
SELECT spell_id, ScriptName
FROM spell_script_names
WHERE spell_id IN (277253, 277639, 278495, 278497, 278506, 7384);
