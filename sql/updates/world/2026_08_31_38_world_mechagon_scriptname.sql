-- 837 blizzlike: map 2097 King Mechagon Enable 150397 ScriptName must equal RegisterCreatureAI(boss_king_mechagon) after creature.id change from 154817. Do not bind template 154817. Do not change 150396 npc_aeriel_unit. Do not change 144248 boss_head_machinist_sparkflux.
UPDATE `creature_template` SET `ScriptName`='boss_king_mechagon' WHERE `entry`=150397;
