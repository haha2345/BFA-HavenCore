-- 837 blizzlike: SHA-Resto 接线山洪/倾盆/Resurgence/高潮。77226 不搬家。204288 不是 8.3 974。
-- 禁止 INSERT 77226/108287/108281/61295/52127 空壳。
-- 禁止 DELETE 1064/73920/974/114052/51564/197995/98020。
-- 禁止用「疾风骤雨」当唯一键。280614 Dummy 0 ≠ 207778 Dummy 5。
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(280614, 'spell_sha_flash_flood'),
(207778, 'spell_sha_downpour'),
(16196, 'spell_sha_resurgence');

DELETE FROM `spell_script_names`
WHERE `spell_id` = 204288 AND `ScriptName` = 'spell_sha_earth_shield';
