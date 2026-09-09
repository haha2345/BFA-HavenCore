-- 837 blizzlike: SHA-C 卸已删 324 闪电之盾错绑。电能/自然守护/幽魂之狼改 cpp 不靠本文件 INSERT。
-- 禁止 INSERT 57994/51514/108271/20608/21169/77130/108287/192106/168534/77223/77226 空壳。
-- 禁止 DELETE 2645/2825/32182/30884/198103/205495/207354/195255/204945。
-- 禁止 DELETE 61245 creature_template。复生 Dummy 30 与 21169 基点 20 不互填、不包空。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 324 AND `ScriptName` = 'spell_sha_lightning_shield';
