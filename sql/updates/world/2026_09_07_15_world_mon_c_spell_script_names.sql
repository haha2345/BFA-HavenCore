-- 837 blizzlike: MON-C 卸嚎镇已删 140023；真气波 selector / 魂体 aura 接线；补真气爆裂治疗 AT 1315。
-- 禁止 INSERT 119381/115078/115450/218164/243435/115176/116841 空脚本。
-- 禁止 INSERT 116709/264348。8676 式对照：切喉手 dump 已有 spear_hand_strike 则保留。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 140023 AND `ScriptName` = 'spell_monk_ring_of_peace_aura';

DELETE FROM `spell_script_names` WHERE `spell_id` = 132466 AND `ScriptName` = 'spell_monk_chi_wave_target_selector';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (132466, 'spell_monk_chi_wave_target_selector');

DELETE FROM `spell_script_names` WHERE `spell_id` = 101643 AND `ScriptName` = 'aura_monk_transcendence';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (101643, 'aura_monk_transcendence');

-- 123986 EFFECT_1 Misc0=1315 治疗 AT。模板 5300 已是 at_monk_chi_burst_heal。
DELETE FROM `spell_areatrigger` WHERE `SpellMiscId` = 1315;
INSERT INTO `spell_areatrigger`
    (`SpellMiscId`, `AreaTriggerId`, `MoveCurveId`, `ScaleCurveId`, `MorphCurveId`, `FacingCurveId`,
     `AnimId`, `AnimKitId`, `DecalPropertiesId`, `TimeToTarget`, `TimeToTargetScale`, `VerifiedBuild`)
VALUES
    (1315, 5300, 393, 0, 0, 0, 0, 0, 0, 590, 1000, 35662);
