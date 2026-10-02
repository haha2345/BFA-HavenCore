UPDATE `quest_objectives` 
SET `Description` = CASE `ID`
    WHEN 256507 THEN 'Help Raggaran'
    WHEN 256508 THEN 'Help Misha Tor\'kren'
    WHEN 256509 THEN 'Help Zen\'Taji'
END
WHERE `ID` IN (256507, 256508, 256509);