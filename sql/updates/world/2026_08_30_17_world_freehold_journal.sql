-- 837 blizzlike: Unmix Freehold journal IDs (Eudora 126848→2093, Trothak 126969→2094).
-- Dump columns are entry / JournalEncounterID. Do not write creatureId / journalEncounterId.
-- Dump has (126848, 2094) and no 126969 row. Leave 126832→2102 and 126983→2095 unchanged.
-- Do not UPDATE/DELETE instance_encounters; keep (2093,126832) (2094,126848) (2095,126969) (2096,126983).

UPDATE `creature_template_journal` SET `JournalEncounterID`=2093 WHERE `entry`=126848;

-- SELECT `entry`, `JournalEncounterID` FROM `creature_template_journal` WHERE `entry`=126969;
-- dump: no row for Trothak; INSERT IGNORE is a no-op if the row already exists on re-run.
INSERT IGNORE INTO `creature_template_journal` (`entry`, `JournalEncounterID`) VALUES (126969, 2094);
