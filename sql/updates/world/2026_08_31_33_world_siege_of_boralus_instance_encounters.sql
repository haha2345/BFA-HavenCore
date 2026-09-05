-- 837 blizzlike: map 1822 DungeonEncounter 2097/2098/2109/2099/2100 missing; KillRewarder credit only. Pair by encounter not by ID order. Enable NPCs 128650/128649/129208/128651/128652 (not 144160/130836). lastEncounterDungeon=0 on all five rows (not journal 2140, not LFG 1700 this wave, not row 2109). Do not UPDATE 2096/2124/2125/2105-2108. Do not touch 2026_08_31_32.
INSERT INTO `instance_encounters` (`entry`, `creditType`, `creditEntry`, `lastEncounterDungeon`, `comment`) VALUES
	(2098, 0, 128650, 0, 'Chopper Redhook'),
	(2097, 0, 128649, 0, 'Sergeant Bainbridge'),
	(2109, 0, 129208, 0, 'Dread Captain Lockwood'),
	(2099, 0, 128651, 0, 'Hadal Darkfathom'),
	(2100, 0, 128652, 0, 'Viq\'Goth');
