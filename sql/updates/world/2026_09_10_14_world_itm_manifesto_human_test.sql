-- 837 blizzlike: ITM 宣言人测。禁止再改 spell_item.cpp。
-- 物品 174103 ON_USE 313948 Dummy 8/5/0。ON_EQUIP 314042 Dummy 1。
-- Dummy 8 保持百分（BasePoints 8 -> 每人 8%）。公开句 within 8 yards 非 DBC，不得把 Dummy 8 改成码。
-- Dummy 5 保持人数上限。公开句 within 5 yards 非 DBC。禁止 allies_end=4 写进 Dummy 5。
-- Dummy 1 装备钩子，1 不得改成码。
-- Coef 2.75913739204 / 0.55182754993 不是 Dummy，走 CalcValue。不要写 2.759f / 0.551f。
-- 314040 不是 ItemEffect，第一章结束脚本 Cast。10 秒是 DurationIndex 1，不要 SetDuration(10000)。
-- 90 秒 CD / 90000 ms 走表，不要写 90000。
-- 单人木桩 allyCount=0，禁止单人直接 x5。
-- 173944 不验收。禁止 INSERT 173944/313148/313194。
-- 人测完成定义是穿 174103 再使用 313948。不允许 .aura 代替穿脱。
-- 禁止 DELETE 313948/314040/314042/303564/303565/277253。
-- 本文件无 INSERT / DELETE。人测走 itm_manifesto_dummy8_5。
SELECT spell_id, ScriptName
FROM spell_script_names
WHERE spell_id IN (
    277253, 303564, 303565, 313948, 314040, 314042, 313148, 313194
)
ORDER BY spell_id, ScriptName;
