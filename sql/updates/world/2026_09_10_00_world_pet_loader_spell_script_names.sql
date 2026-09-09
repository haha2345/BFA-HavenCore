-- 837 blizzlike: PET loader。声明并调用 AddSC_pet_spell_scripts 后，只给仍存在的 35695 绑 spell_gen_pet_calculate。
-- 禁止 INSERT 19591/61013/61017/61697/34902/34903/34904/54566/34947/34956/34957/34958/51906/1964。
-- 禁止 DELETE 51963/16827/17253/49966/55342/51533/205636/104316/42651/46584。
-- 34902 Dummy 0 残留不读，不包空。20782 Aura 79 的 60 不是 Dummy，不是继承 60% AP。
-- 禁止把 SimC 0.6/0.5/0.4/1.0/0.55/1.15/1.25/0.4*1.06 写进 Dummy 或 InitStatsForLevel。
DELETE FROM `spell_script_names` WHERE `spell_id` = 35695 AND `ScriptName` = 'spell_gen_pet_calculate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (35695, 'spell_gen_pet_calculate');
