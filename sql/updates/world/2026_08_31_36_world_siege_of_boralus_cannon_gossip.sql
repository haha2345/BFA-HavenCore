-- 837 blizzlike: dump 137123 npcflag=0; HandleGossipHelloOpcode requires UNIT_NPC_FLAG_GOSSIP. Keep IconName vehichlecursor; do not switch to OnSpellClick.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1 WHERE `entry` = 137123;
