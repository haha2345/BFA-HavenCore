-- 837 blizzlike: 暴怒父技能 184367 dump 无 spell_script_names；五段伤害已接线。
-- 狂怒斩杀 5308 需要独立 AfterCast 摘 280776，禁止绑到武器耗怒斩杀 spell_warr_execute。
DELETE FROM `spell_script_names` WHERE `spell_id` = 184367 AND `ScriptName` = 'spell_warr_rampage';
DELETE FROM `spell_script_names` WHERE `spell_id` = 5308 AND `ScriptName` IN ('spell_warr_execute_fury', 'spell_warr_execute');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (184367, 'spell_warr_rampage'),
    (5308, 'spell_warr_execute_fury');
