-- 837 blizzlike: 射击急速射击 / 百发百中 / 多重 257620 / 稳固 Dummy 10。
-- 瞄准 dump 已绑 19434，不要卸。不要 INSERT 260242 / 260393 空类。
-- 不要 INSERT 193526。不要给 258925 式空键包脚本。
DELETE FROM `spell_script_names` WHERE `spell_id` = 257044 AND `ScriptName` = 'spell_hun_rapid_fire';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (257044, 'spell_hun_rapid_fire');

DELETE FROM `spell_script_names` WHERE `spell_id` = 288613 AND `ScriptName` = 'spell_hun_trueshot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (288613, 'spell_hun_trueshot');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 2643 AND `ScriptName` = 'spell_hun_multi_shot';
DELETE FROM `spell_script_names` WHERE `spell_id` = 257620 AND `ScriptName` = 'spell_hun_mm_multi_shot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (257620, 'spell_hun_mm_multi_shot');

DELETE FROM `spell_script_names` WHERE `spell_id` = 56641 AND `ScriptName` = 'spell_hun_steady_shot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (56641, 'spell_hun_steady_shot');
