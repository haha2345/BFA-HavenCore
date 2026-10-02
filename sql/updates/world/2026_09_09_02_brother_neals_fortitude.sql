-- Fix issue 501: Brother Neals applies too much stamina to low level characters
-- Change the hardcoded flat-stamina spell (74973) to the standard scaling BFA Power Word: Fortitude (21562)

UPDATE `smart_scripts` SET `action_param1` = 21562 WHERE `entryorguid` = 952 AND `action_type` = 11 AND `action_param1` = 74973;
