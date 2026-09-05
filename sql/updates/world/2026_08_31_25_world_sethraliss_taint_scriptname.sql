-- 837 blizzlike: 273677 Taint is Dummy; script applies difficulty basepoints as healing reduction.

DELETE FROM `spell_script_names` WHERE `spell_id`=273677 AND `ScriptName`='spell_sethraliss_taint';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(273677, 'spell_sethraliss_taint');
