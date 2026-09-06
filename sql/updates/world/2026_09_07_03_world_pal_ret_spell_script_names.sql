-- 837 blizzlike: 8.3 灰烬觉醒是 255937。dump 把脚本绑在军团昏迷号 205290。
-- 处决宣判 267798 dump 无行。不要接神圣之锤 198034。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 205290 AND `ScriptName` = 'spell_pal_wake_of_ashes';

DELETE FROM `spell_script_names` WHERE `spell_id` = 255937 AND `ScriptName` = 'spell_pal_wake_of_ashes';
DELETE FROM `spell_script_names` WHERE `spell_id` = 267798 AND `ScriptName` = 'spell_pal_execution_sentence';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (255937, 'spell_pal_wake_of_ashes'),
    (267798, 'spell_pal_execution_sentence');
