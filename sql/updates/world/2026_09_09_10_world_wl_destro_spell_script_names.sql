-- 837 blizzlike: WL-Destro 卸 137046 灵魂榨取误绑名。不包闪燃/逆向熵/至高术/动荡空壳。
-- 禁止 INSERT 267115/205148/266086/113858/77220/196586/5740/108685/108686/324536 空壳。
-- 禁止 DELETE 116858/29722/348/157736/193541/17962/80240/152108/17877/196447/6353/196412/196414/42223/77220/117828。
-- 禁止 DELETE (5740, at_hor_impenetrable_door)。禁止 DELETE 196586 神器行。
DELETE FROM `spell_script_names`
WHERE `spell_id` = 137046 AND `ScriptName` IN (
    'spell_warlock_soul_leech',
    'spell_warl_soul_leech_aura',
    'spell_warl_soul_leach_applier'
);
