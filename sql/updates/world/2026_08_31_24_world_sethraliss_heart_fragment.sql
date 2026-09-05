-- 837 blizzlike: Energy Fragment (142929) dump npcflag=0; gossip click needs UNIT_NPC_FLAG_GOSSIP. Do not change ScriptName; 278894 is instance OnUnitDeath, not SAI death cast.

UPDATE `creature_template` SET `npcflag` = `npcflag` | 1 WHERE `entry` = 142929;
