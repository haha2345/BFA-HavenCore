-- 837 blizzlike: map 1763 古代开关 288478/288477 图上有刷但 ScriptName 空，挂上已注册的 go_ad_switch。
UPDATE `gameobject_template` SET `ScriptName`='go_ad_switch' WHERE `entry` IN (288478, 288477);
