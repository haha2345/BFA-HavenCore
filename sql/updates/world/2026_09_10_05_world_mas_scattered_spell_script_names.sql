-- 837 blizzlike: MAS 散落精通。家留职业文件。禁止 spell_mastery_* 新类收编。
-- 76806 Dummy 0；30% 观察窗口非 DBC，不得进 Dummy 0。
-- 77485 Dummy 0/125；125 不得改写成 6 秒。77489 周期 3000 ms。
-- 271534 Dummy 0；Coef 1.35 不是 Dummy；禁止再乘 +12%。
-- 117907 Dummy 0/0；Coef 3 不是 Dummy；治疗号 191894。
-- 183997 Dummy 0；10/40 码观察窗口不得进 Dummy。
-- 禁止 INSERT 77495/203747/77513/76857/262111/76657/77215/77223/77226/77492/77486。
-- 禁止 DELETE 117906/195630/77535/76856/77220。
DELETE FROM `spell_script_names` WHERE `spell_id` = 76806 AND `ScriptName` = 'spell_rog_main_gauche';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (76806, 'spell_rog_main_gauche');
DELETE FROM `spell_script_names` WHERE `spell_id` = 77485 AND `ScriptName` = 'spell_pri_echo_of_light';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (77485, 'spell_pri_echo_of_light');
DELETE FROM `spell_script_names` WHERE `spell_id` = 117907 AND `ScriptName` = 'spell_monk_gust_of_mists';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (117907, 'spell_monk_gust_of_mists');
