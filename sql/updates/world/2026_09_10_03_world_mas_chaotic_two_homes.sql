-- 837 blizzlike: MAS 混乱能量两处家核对。Dummy 0/0。
-- 吸收 Aura 家在 spell_warlock.cpp spell_warl_chaotic_energies，读 EFFECT_1。
-- 伤害浮动 PlayerScript 家在 spell_mastery.cpp warlock_mastery_chaotic_energy，ceil(EFFECT_0/2)+urand 是非 DBC 观察窗口，不得写成 Dummy。
-- 禁止搬家、禁止 DELETE 77220 行、禁止再 INSERT 进 spell_mastery_*、禁止删一边、禁止拆两条原子。
-- BonusCoef 2 / 0.666 不是 Dummy。10.0 删减伤弃用。本文件无 INSERT / DELETE。
-- 人测走 mas_wl_chaotic_two_homes。
SELECT spell_id, ScriptName FROM spell_script_names WHERE spell_id = 77220;
