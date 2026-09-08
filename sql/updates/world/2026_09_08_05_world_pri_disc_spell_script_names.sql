-- 837 blizzlike: 戒律暗影盟约204065/福音246287。
-- 禁止 INSERT 214621/33206/271534/193134/238063/271466/47536/280391/123040/34433/314867/197862/109964/200829 空壳。
-- 禁止 DELETE 17/47540/186263/81749/194509/585/129250/204215/198068/109964。
DELETE FROM `spell_script_names` WHERE `spell_id` = 204065 AND `ScriptName` = 'spell_pri_shadow_covenant';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (204065, 'spell_pri_shadow_covenant');

DELETE FROM `spell_script_names` WHERE `spell_id` = 246287 AND `ScriptName` = 'spell_pri_evangelism';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (246287, 'spell_pri_evangelism');
