-- 837 blizzlike: bfa_spell_fracking_totem_summon AfterCast recasts 268204; bind 257480 not 268204 (recursion). Resonant pulse bind 258622.
DELETE FROM `spell_script_names` WHERE `spell_id`=257480 AND `ScriptName`='bfa_spell_fracking_totem_summon';
DELETE FROM `spell_script_names` WHERE `spell_id`=258622 AND `ScriptName`='bfa_spell_resonant_pulse';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
	(257480, 'bfa_spell_fracking_totem_summon'),
	(258622, 'bfa_spell_resonant_pulse');
