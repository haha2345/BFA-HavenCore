-- 837 blizzlike: map 1594 Azerokk dump ScriptName boss_azerokk != RegisterCreatureAI(bfa_boss_azerokk); helpers 129802/129804/136500 ScriptName empty. Do not rename C++ structs. Do not INSERT instance_encounters 2105-2108.
UPDATE `creature_template` SET `ScriptName`='bfa_boss_azerokk' WHERE `entry`=129227;
UPDATE `creature_template` SET `ScriptName`='bfa_npc_earthrager' WHERE `entry`=129802;
UPDATE `creature_template` SET `ScriptName`='bfa_npc_fracking_totem_selector' WHERE `entry`=129804;
UPDATE `creature_template` SET `ScriptName`='bfa_npc_fracking_totem' WHERE `entry`=136500;
