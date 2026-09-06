-- 837 blizzlike: 玩家死亡之门是 50977，dump 只绑了点门 52751。
-- AMS 48707 双绑 _self 会叠两套 40/50 上限；本波只留 spell_dk_anti_magic_shell。
-- 45524 双绑 chains + chilblains 都保留；若 spell_linked_spell 仍把锁链接到 55095 则卸掉。
-- 48265 死亡脚步仍绑 spell_dk_presence 会清符能；只卸绑定，不要改类去「兼容死亡脚步」。
-- 不要 DELETE 48263（第三次战争的老兵，120 鲜血仍用）。
DELETE FROM `spell_script_names` WHERE `spell_id` = 50977 AND `ScriptName` = 'spell_dk_death_gate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (50977, 'spell_dk_death_gate');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 48707 AND `ScriptName` = 'spell_dk_anti_magic_shell_self';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 48265 AND `ScriptName` = 'spell_dk_presence';

DELETE FROM `spell_linked_spell`
WHERE `spell_trigger` = 45524 AND `spell_effect` = 55095;
