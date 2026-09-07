-- 837 blizzlike: BM 倒刺/KC/野性呼唤/顺劈 dump 已有行则保留。只补眼镜蛇 Dummy 1。
-- 不要改 217200 的 ScriptName（仍 spell_hun_dire_frenzy）。
-- 不要 INSERT 272790/246152/321530。不要 INSERT 272651。
DELETE FROM `spell_script_names` WHERE `spell_id` = 193455 AND `ScriptName` = 'spell_hun_cobra_shot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (193455, 'spell_hun_cobra_shot');
