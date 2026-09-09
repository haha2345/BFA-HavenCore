-- 837 blizzlike: DRU-Bal 接线 8.3 新月/自然平衡/自然之力。77492 是表 modifier 不走本表。
-- 禁止 INSERT 77492/202767/202768/202771/202360/194223/203245/48517/48518 空壳或当 8.3 键。
-- 禁止 DELETE 190984/194153/78674/191034/8921/93402/202767/208253。
-- 禁止用 15000 / 20 秒覆盖 274281 的 25000。自然平衡 Dummy 必须点名 idx1/2/3。
-- 274281 Dummy 0 残留；274282 Dummy 0 残留；274283 Dummy 202788/202787/0 保持列值，不要写成 Dummy 0。
-- 三连 LearnSpell/RemoveSpell 8.3 自己的键。禁止 AddAura(202787/202788/202789) 切回 202767。
-- 自然平衡 PreventDefault EFFECT_0；战斗 Dummy 2/3 秒；脱战一次性补到 Dummy 50。禁止每 tick / 每 3 秒 +50。
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(274281, 'spell_dru_new_moon'),
(274282, 'spell_dru_half_moon'),
(274283, 'spell_dru_full_moon'),
(202430, 'spell_dru_natures_balance'),
(205636, 'spell_dru_force_of_nature');
