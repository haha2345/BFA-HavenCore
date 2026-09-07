-- 837 blizzlike: ROG-C 卸 1833 披风与匕首。表已表达技能不包空脚本。
-- 禁止 INSERT 1766/185311/5277/1966/13750/6770/2094/31224/114018/1804/921/2983/36554/1833/79140。
-- 8676 卸绑在 _13。703 的 cloak_and_dagger 卸绑在 _12。
DELETE FROM `spell_script_names` WHERE `spell_id` = 1833 AND `ScriptName` = 'spell_rog_cloak_and_dagger';
