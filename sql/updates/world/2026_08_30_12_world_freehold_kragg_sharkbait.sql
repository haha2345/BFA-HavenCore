-- 837 blizzlike: Bind combat mount 126841 to npc_sharkbait; stop 256056 from summoning a second parrot.

UPDATE `creature_template` SET `ScriptName`='npc_sharkbait' WHERE `entry`=126841;

DELETE FROM `spell_script_names` WHERE `spell_id`=256056 AND `ScriptName`='spell_spawn_parrot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(256056, 'spell_spawn_parrot');
