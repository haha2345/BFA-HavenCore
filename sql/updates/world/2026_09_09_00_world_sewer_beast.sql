-- Fix for Sewer Beast (3581) spawning multiple times and not moving

DELETE FROM pool_template WHERE entry = 3581;
INSERT INTO pool_template (entry, max_limit, description) VALUES (3581, 1, 'Sewer Beast');

DELETE FROM pool_creature WHERE guid IN (10604700, 52499, 308329);
INSERT INTO pool_creature (guid, pool_entry, chance, description) VALUES
(10604700, 3581, 0, 'Sewer Beast'),
(52499, 3581, 0, 'Sewer Beast'),
(308329, 3581, 0, 'Sewer Beast');

UPDATE creature SET MovementType = 1, spawndist = 25 WHERE id = 3581;
