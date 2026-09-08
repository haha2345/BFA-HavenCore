-- 837 blizzlike: 暗影净化疾病213634/Surrender/Legacy/Hallucinations。
-- 禁止 INSERT 15407/589/205065/194248/77486/205351/205385/47585/15487/34433 空壳。
-- 禁止 DELETE 205065/228260/194249/234746/8092/34914/78203/263165/280711/263346/32379/15286。
DELETE FROM `spell_script_names` WHERE `spell_id` = 213634 AND `ScriptName` = 'spell_pri_purify_disease';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (213634, 'spell_pri_purify_disease');

DELETE FROM `spell_script_names` WHERE `spell_id` = 193223 AND `ScriptName` = 'spell_pri_surrender_to_madness';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (193223, 'spell_pri_surrender_to_madness');

DELETE FROM `spell_script_names` WHERE `spell_id` = 193225 AND `ScriptName` = 'spell_pri_legacy_of_the_void';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (193225, 'spell_pri_legacy_of_the_void');

DELETE FROM `spell_script_names` WHERE `spell_id` = 280752 AND `ScriptName` = 'spell_pri_hallucinations';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (280752, 'spell_pri_hallucinations');
