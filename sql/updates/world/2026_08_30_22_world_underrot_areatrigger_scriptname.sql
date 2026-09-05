-- 837 blizzlike: Spell ATs use areatrigger_template.ScriptName; align with C++ bfa_at_* (areatrigger_scripts is skipped at runtime).

UPDATE `areatrigger_template` SET `ScriptName`='bfa_at_vile_expulsion' WHERE `Id`=17928;
UPDATE `areatrigger_template` SET `ScriptName`='bfa_at_cragmaw_charge' WHERE `Id`=17014;
UPDATE `areatrigger_template` SET `ScriptName`='bfa_at_volatile_pod_explosion' WHERE `Id`=18227;
