-- 837 blizzlike: Devour Vitality (An'zig Vra). 316617 is HEALTH_LEECH;
-- script fills SetEffectValue from caster max HP * Dummy. Do NOT DealHeal.
-- 316615 mask0 already has melee auto-attack; do NOT write spell_proc.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (316615, 316617);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(316615, 'spell_devour_vitality_proc'),
(316617, 'spell_devour_vitality_leech');
