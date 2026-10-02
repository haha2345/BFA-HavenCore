-- guid 26 (136470) Motherlode map gate, and clear 154741 ScriptName.
-- Task1 and Task2 are independent. A closed gate writes 0 rows and does not stop the other task.
-- Session TEMPORARY tables only. No permanent DDL, no START TRANSACTION / ROLLBACK.
-- Rollback is a separate file generated from the before snapshot. It is not executed here.
-- Temp names use the npc11_ task prefix: npc11_pre26 = plan pre26, npc11_before26 = plan before26,
-- npc11_pre741 = plan pre741, npc11_before741 = plan before741.

DROP TEMPORARY TABLE IF EXISTS npc11_pre26, npc11_pre741, npc11_before26, npc11_before741;

CREATE TEMPORARY TABLE npc11_before26 (SourceGroup INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO npc11_before26
SELECT c.SourceGroup FROM conditions c
WHERE c.SourceTypeOrReferenceId=22 AND c.SourceEntry=-26 AND c.SourceId=0 AND c.ElseGroup=0
  AND c.ConditionTypeOrReference=22 AND c.ConditionTarget=1 AND c.ConditionValue1=1594
  AND c.ConditionValue2=0 AND c.ConditionValue3=0 AND c.NegativeCondition=1
  AND c.Comment='mlode-guid26: map!=1594';

CREATE TEMPORARY TABLE npc11_before741 (old_name VARCHAR(64) NOT NULL);
INSERT INTO npc11_before741 SELECT IFNULL(ScriptName,'') FROM creature_template WHERE entry=154741;

CREATE TEMPORARY TABLE npc11_pre26 (bad26 INT NOT NULL);
INSERT INTO npc11_pre26 SELECT
 (SELECT IF(COUNT(*)=1,0,1) FROM creature cr JOIN creature_template tp ON tp.entry=cr.id
   WHERE cr.guid=26 AND cr.id=136470 AND cr.map=1594 AND IFNULL(cr.ScriptName,'')='' AND tp.AIName='SmartAI')
+(SELECT IF(COUNT(*)=0,0,1) FROM smart_scripts WHERE entryorguid IN (136470,-136470))
+(SELECT IF(COUNT(DISTINCT id)=26 AND MIN(id)=0 AND MAX(id)=25 AND SUM(event_type NOT IN (10,52))=0 AND COUNT(*)>0,0,1)
   FROM smart_scripts WHERE entryorguid=-26 AND source_type=0)
+(SELECT COUNT(*) FROM conditions c
   WHERE c.SourceTypeOrReferenceId=22 AND c.SourceEntry=-26 AND c.SourceId=0
     AND NOT (c.ElseGroup=0 AND c.ConditionTypeOrReference=22 AND c.ConditionTarget=1
       AND c.ConditionValue1=1594 AND c.ConditionValue2=0 AND c.ConditionValue3=0
       AND c.NegativeCondition=1 AND c.Comment='mlode-guid26: map!=1594'
       AND c.SourceGroup IN (SELECT ss.id+1 FROM smart_scripts ss
         WHERE ss.entryorguid=-26 AND ss.source_type=0 AND ss.event_type<>61)));

CREATE TEMPORARY TABLE npc11_pre741 (t2act VARCHAR(8) NOT NULL);
INSERT INTO npc11_pre741
SELECT IFNULL(x.act,'fail') FROM (SELECT 1) d
LEFT JOIN (
  SELECT CASE
    WHEN ct.ScriptName='npc_squirt_bot' AND ct.AIName='SmartAI' AND s.ok=1 AND o.ok=1 AND sp.ok=1 THEN 'apply'
    WHEN ct.ScriptName='' AND ct.AIName='SmartAI' AND s.ok=1 AND o.ok=1 AND sp.ok=1 THEN 'noop'
    ELSE 'fail' END act
  FROM creature_template ct
  JOIN (SELECT COUNT(*)>0 ok FROM smart_scripts WHERE entryorguid=154741 AND source_type=0 AND action_type=11 AND action_param1=297901) s
  JOIN (SELECT COUNT(*)=2 ok FROM creature_template t WHERE t.entry IN (154746,154759) AND IFNULL(t.ScriptName,'')=''
    AND (SELECT COUNT(*) FROM smart_scripts z WHERE z.entryorguid=t.entry AND z.source_type=0 AND z.action_type=11 AND z.action_param1=297901)>0) o
  JOIN (SELECT COUNT(*)=1 ok FROM creature WHERE guid=3300000000000910 AND IFNULL(ScriptName,'')='') sp
  WHERE ct.entry=154741
) x ON 1=1;

INSERT INTO conditions (
  SourceTypeOrReferenceId,SourceGroup,SourceEntry,SourceId,ElseGroup,
  ConditionTypeOrReference,ConditionTarget,ConditionValue1,ConditionValue2,ConditionValue3,
  NegativeCondition,ErrorType,ErrorTextId,ScriptName,Comment)
SELECT 22, d.id+1, -26, 0, 0, 22, 1, 1594, 0, 0, 1, 0, 0, '', 'mlode-guid26: map!=1594'
FROM (
  SELECT DISTINCT ss.id
  FROM smart_scripts ss JOIN npc11_pre26 g ON g.bad26=0
  WHERE ss.entryorguid=-26 AND ss.source_type=0 AND ss.event_type<>61
    AND NOT EXISTS (
      SELECT 1 FROM conditions c
      WHERE c.SourceTypeOrReferenceId=22 AND c.SourceGroup=ss.id+1 AND c.SourceEntry=-26
        AND c.SourceId=0 AND c.ElseGroup=0 AND c.ConditionTypeOrReference=22
        AND c.ConditionTarget=1 AND c.ConditionValue1=1594 AND c.ConditionValue2=0
        AND c.ConditionValue3=0 AND c.NegativeCondition=1
        AND c.Comment='mlode-guid26: map!=1594')
) d;

UPDATE creature_template ct
JOIN npc11_pre741 g ON g.t2act='apply'
SET ct.ScriptName=''
WHERE ct.entry=154741 AND ct.ScriptName='npc_squirt_bot' AND ct.AIName='SmartAI';

DROP TEMPORARY TABLE IF EXISTS npc11_pre26, npc11_pre741, npc11_before26, npc11_before741;
