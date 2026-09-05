-- 837 blizzlike: Trothak 126969 is vehicle 5658; hammer/saw sharks occupy seats 0/1 so toss reads passengers. Do not touch dump static shark guids.

-- LoadVehicleTemplateAccessories skips vehicle_template_accessory rows whose entry has no
-- npc_spellclick_spells (ObjectMgr.cpp ~3281-3284). Dump has no 126969 spellclick, so the
-- accessory INSERTs below would be dropped. 46598 is VEHICLE_SPELL_RIDE_HARDCODED.
-- InstallAccessory can still Ride Hardcoded without a valid spellclick, but the loader
-- already discarded the rows. Do not touch dump.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry`=126969 AND `spell_id`=46598;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES (126969, 46598, 1, 0);

INSERT INTO `vehicle_template_accessory`
(`entry`, `accessory_entry`, `seat_id`, `minion`, `description`, `summontype`, `summontimer`) VALUES
(126969, 129448, 0, 1, 'Trothak - Hammerhead Shark', 6, 30000),
(126969, 129359, 1, 1, 'Trothak - Sawtooth Shark', 6, 30000);
