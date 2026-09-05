-- 837 blizzlike: map 2097 King Mechagon Enable is 150397 (0 static spawns). Existing guid 3400000000001672 is nameless 154817 at the same layer as 150396. UPDATE id only; do not invent xyz; do not INSERT 150397; do not INSERT 152619.
UPDATE `creature` SET `id`=150397 WHERE `guid`=3400000000001672 AND `map`=2097 AND `id`=154817;
