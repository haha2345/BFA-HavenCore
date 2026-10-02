-- BFA-HavenCore

-- Fix: Westfall enemy mobs invisible to players after phase_area entries for phases 170/171 were added.

INSERT IGNORE INTO `phase_area` (`AreaId`, `PhaseId`, `Comment`)
VALUES (40, 169, 'Westfall - Default Phase keeps base creatures visible');
