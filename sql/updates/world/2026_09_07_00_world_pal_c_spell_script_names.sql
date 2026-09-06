-- 837 blizzlike: 8.3 审判是三个 SpellID。dump 只绑了惩戒 20271。
-- 19740 / 20217 是力量/王者祝福孤儿名，35662 SpellName 无行，cpp 无类。
-- 203538 大于王者祝福 8.3 惩戒仍活，禁止 DELETE。
DELETE FROM `spell_script_names` WHERE `spell_id` IN (275773, 275779) AND `ScriptName` = 'spell_pal_judgment';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (275773, 'spell_pal_judgment'),
    (275779, 'spell_pal_judgment');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 19740 AND `ScriptName` = 'spell_pal_blessing_of_might';
DELETE FROM `spell_script_names`
WHERE `spell_id` = 20217 AND `ScriptName` = 'spell_pal_blessing_of_kings';
