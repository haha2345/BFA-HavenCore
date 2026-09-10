-- 837 blizzlike: AZ 浓缩火焰人测。禁止再改 spell_azerite.cpp / loader。
-- EssenceID 12 学会 295373。Dummy 100/100。Coef 16.71 不是 Dummy。
-- 30 秒是 SpellCategory 1852（MaxCharges 1 / ChargeRecoveryTime 30000），不是 Dummy。
-- SpellCooldowns 295373 末列 1500 是 GCD 列，只登记。
-- 禁止 Learn / INSERT 299349（末列 1000，School 4->1，换号会把 GCD 从 1500 改成 1000）。
-- 67 / 1000 / 1500 / 30 / 1.5 / 16.71 不得进 Dummy 100。
-- 295377 Dummy 75 / 295368 DurationIndex 32=6秒 不验收、不 INSERT。
-- 191837 不是 AZE。禁止 DELETE spell_monk_essence_font。
-- 禁止 INSERT 295374/295375/295377/295368/295379/299349/191837。
-- 禁止 DELETE 295373/295376/278495/278497/277253。
-- 本文件无 INSERT / DELETE。人测走 az_concentrated_flame_learn_295373。
SELECT spell_id, ScriptName
FROM spell_script_names
WHERE spell_id IN (295373, 295376, 299349, 191837, 277253);
