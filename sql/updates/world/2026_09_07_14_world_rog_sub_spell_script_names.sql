-- 837 blizzlike: 敏锐飞镖龙卷 277925、秘密手法 280719。卸笼罩旧号 206237。
-- 禁止 INSERT 238104 空类（Aura 411 引擎已实现 +1 影舞层）。禁止 INSERT 212283/121471 空类。
-- 刺骨 196819 dump 已有 spell_rog_eviscerate 则保留；不要 DELETE 2098 那一行。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 206237 AND `ScriptName` = 'spell_rog_enveloping_shadows';

DELETE FROM `spell_script_names` WHERE `spell_id` = 277925 AND `ScriptName` = 'spell_rog_shuriken_tornado';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (277925, 'spell_rog_shuriken_tornado');

DELETE FROM `spell_script_names` WHERE `spell_id` = 280719 AND `ScriptName` = 'spell_rog_secret_technique';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (280719, 'spell_rog_secret_technique');
