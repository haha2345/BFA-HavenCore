-- 837 blizzlike: WL-C 卸黑暗契约双绑、228974 盖 108370、204730 恐惧错绑。
-- 禁止 INSERT 5484/1454/108415/324536/698/1098/30283/264874/688/697/712/691/119898/6201/20707 空壳。
-- 禁止 DELETE 5782/755/104773/108370/108416 的 spell_warlock_dark_pact/111400/111771/219272/234153/48018/48020/710/5697/126/23517/6262/196586/77220。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 108416 AND `ScriptName` = 'spell_warl_dark_pact';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 228974 AND `ScriptName` = 'spell_warl_soul_leech_aura';

DELETE FROM `spell_script_names`
WHERE `spell_id` = 204730 AND `ScriptName` = 'spell_warl_fear_buff';
