-- BFA-HavenCore

UPDATE smart_scripts
SET action_type = 75, -- SMART_ACTION_ADD_AURA
    comment = REPLACE(comment, 'Cast', 'Add aura')
WHERE action_param1 = 5628
  AND source_type = 0
  AND entryorguid IN (2011, 2012, 2013, 2014);
