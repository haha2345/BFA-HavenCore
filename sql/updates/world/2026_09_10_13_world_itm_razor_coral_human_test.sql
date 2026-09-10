-- 837 blizzlike: ITM 珊瑚人测。禁止再改 spell_item.cpp。
-- 物品 169311 ON_USE 303564 Dummy 0 是开关钩子。第一次 303572+303568，第二次摘层 303570。
-- 金额读 304877 / 303573 CalcValue，不读 Dummy 0。不要写 0.265f / 22.99f。
-- 303565 Dummy 0。ppm copy 167<-124 rate 6.0 是表。不要写 6.0f。Dummy 0 不得改成 6。
-- 40 码是 RangeIndex 5。20 秒 CD 走表。不要 SetDuration / 不要写 20000。
-- 303568 Dummy 0；120s/100 层；RangeIndex 35=35.0 码不是 Dummy。
-- 303570 / 303572 无 Dummy，不 INSERT。302855 不是 303564。
-- 人测完成定义是穿 169311 再使用 303564。不允许 .aura 代替穿脱。
-- .aura 303568 只作调试，不得当闭环。
-- 禁止 INSERT 303572/303570/303568/303573/304877/302855/277253。
-- 禁止 DELETE 303564/303565/313948/314040/314042/277253。
-- 本文件无 INSERT / DELETE。人测走 itm_razor_coral_dummy0。
SELECT spell_id, ScriptName
FROM spell_script_names
WHERE spell_id IN (
    277253, 303564, 303565, 303568, 303570, 303572, 303573, 304877,
    313948, 314040, 314042, 313148, 313194, 302855, 169311
)
ORDER BY spell_id, ScriptName;
