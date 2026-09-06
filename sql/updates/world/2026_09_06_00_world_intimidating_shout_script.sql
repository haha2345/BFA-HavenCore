-- 837 blizzlike: 破胆怒吼 5246 的脚本类是 SpellScript，AddSC 用 new 进不了 ScriptMgr；dump 无 spell_script_names 行。
DELETE FROM `spell_script_names` WHERE `spell_id` = 5246 AND `ScriptName` = 'spell_warr_intimidating_shout';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (5246, 'spell_warr_intimidating_shout');
