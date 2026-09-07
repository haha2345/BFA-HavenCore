-- 837 blizzlike: 狂徒武器大师 200733、Restless Blades 79096、灌铅 256170、刀锋冲刺 271877。
-- 卸 1752 影袭错绑、卸 8676 披风与匕首。灌铅绑 13750（只挂钩 256171，不重做急速）。禁止 INSERT 185763 空类。禁止把 200733 绑到敏锐 `spell_rog_weaponmaster`。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 1752 AND `ScriptName` = 'spell_rog_sinister_strike';
DELETE FROM `spell_script_names`
WHERE `spell_id` = 8676 AND `ScriptName` = 'spell_rog_cloak_and_dagger';

DELETE FROM `spell_script_names` WHERE `spell_id` = 200733 AND `ScriptName` = 'spell_rog_weaponmaster_outlaw';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (200733, 'spell_rog_weaponmaster_outlaw');

DELETE FROM `spell_script_names` WHERE `spell_id` = 79096 AND `ScriptName` = 'spell_rog_restless_blades';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (79096, 'spell_rog_restless_blades');

DELETE FROM `spell_script_names` WHERE `spell_id` = 13750 AND `ScriptName` = 'spell_rog_loaded_dice';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (13750, 'spell_rog_loaded_dice');

DELETE FROM `spell_script_names` WHERE `spell_id` = 271877 AND `ScriptName` = 'spell_rog_blade_rush';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (271877, 'spell_rog_blade_rush');
