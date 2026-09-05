-- 837 blizzlike: map 1771 DungeonEncounter 2101-2104 missing from dump; KillRewarder credit only. Do not expect BossAI _dungeonEncounterId. lastEncounterDungeon=0 (not journal 2096, not LFG 1713/1714/1778 this wave).
INSERT INTO `instance_encounters` (`entry`, `creditType`, `creditEntry`, `lastEncounterDungeon`, `comment`) VALUES
	(2101, 0, 127479, 0, 'The Sand Queen'),
	(2102, 0, 127484, 0, 'Jes Howlis'),
	(2103, 0, 127490, 0, 'Knight Captain Valyri'),
	(2104, 0, 127503, 0, 'Overseer Korgus');
