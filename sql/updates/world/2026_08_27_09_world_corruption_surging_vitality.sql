-- 837 blizzlike: Surging Vitality (活力涌动). 318211 DBC BP is 0; script fills
-- vers rating from the rank Scaled (CalcValue). Driver Base was hotfixed to 0.
-- Taken-proc mask stays on DBC. Do NOT write spell_proc.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (318212, 318211);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(318212, 'spell_surging_vitality_proc'),
(318211, 'spell_surging_vitality_buff');
