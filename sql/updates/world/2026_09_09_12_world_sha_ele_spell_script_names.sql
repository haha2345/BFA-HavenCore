-- 837 blizzlike: SHA-Ele 接线 8.3 风暴守护者/冰怒/余震/元素升腾；过载箭/链过载绑积雷脚本产 Dummy 3。168534 是 PlayerScript 不走本表。
-- 禁止 INSERT 168534/77223/210707/205495/214815/108287/260895 空壳或当 8.3 键。
-- 禁止 DELETE 188196/51505/8042/61882/188389/188443/117014/77756/198067/205495。
-- 禁止 DELETE 210643（元素图腾掌握 dump，本波不验收该行）。
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(191634, 'spell_sha_stormkeeper'),
(210714, 'spell_sha_icefury'),
(273221, 'spell_sha_aftershock'),
(114050, 'spell_sha_ascendance_elemental'),
(45284, 'spell_sha_lightning_bolt_elem'),
(45297, 'spell_sha_chain_lightning');
