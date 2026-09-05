-- 837 blizzlike: map 1762 DungeonEncounter 2139/2142/2140/2143 missing; KillRewarder credit only. Pair by encounter not by ID order. credit 2140=135472 Zanazal (opens 288637). lastEncounterDungeon=0 (not journal 2172, not LFG 1784/1785 this wave). Do not UPDATE 2124/2125/2096. Do not touch creature_template_journal (133379,2142).
INSERT INTO `instance_encounters` (`entry`, `creditType`, `creditEntry`, `lastEncounterDungeon`, `comment`) VALUES
	(2139, 0, 135322, 0, 'The Golden Serpent'),
	(2142, 0, 134993, 0, 'Mchimba the Embalmer'),
	(2140, 0, 135472, 0, 'The Council of Tribes'),
	(2143, 0, 136160, 0, 'King Dazar');
