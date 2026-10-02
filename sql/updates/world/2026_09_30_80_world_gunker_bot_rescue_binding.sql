-- BFA 8.3.7.35662 / DUN-2097-GUNKER-FX, approved robot-rescue plan Task1.
-- Plan-stage filename retained. Generated only; not executed or loaded online.
-- Bind 153377 -> npc_mechagon_gunker_goop and only 298124 -> spell_gunker_gooped_bot.
-- Before: one 153377 template, AIName=SmartAI, ScriptName strictly empty;
--         no 298124 mapping. Own already-bound / partly-bound states are allowed.
-- After: same SmartAI, ScriptName=npc_mechagon_gunker_goop, one exact 298124 pair.
-- Preserve all SAI and every other template column; do not add creature spawns.
-- The template covers ALL 153377 instances. Task0's static-bot / Aura GUID checks
-- limit rescue behavior; this is not a template binding restricted to three A's.
-- All names are compared as BINARY; NULL, case variants and trailing bytes fail.
-- SAI guards include both signs at every source_type; spell guards include ranks.
-- apply = this run filled the missing own binding(s) and verified the targets;
-- noop = both targets already existed, both ROW_COUNT values are 0, guards pass;
-- fail = initial gate closed, final guard/target failed, or row accounting differs.
-- A closed initial gate writes neither binding, even if later state changes.
-- Each DML rechecks live guards. These statements do NOT provide a cross-table
-- atomic commit or online hot reload. A later guard failure can leave one binding.
-- Any future authorized execution requires a maintenance window without concurrent
-- binding writers and retention of ALL result sets (especially before + row counts).
-- No permanent DDL, transaction claim, INSERT IGNORE, mapping replacement or SAI DELETE.

DROP TEMPORARY TABLE IF EXISTS gunker_fx_bind_pre, gunker_fx_bind_before;

-- Aggregate to exactly one snapshot row even when the template is missing.
-- Do not coalesce NULL names into an empty string.
CREATE TEMPORARY TABLE gunker_fx_bind_before AS
SELECT t.template_rows, t.before_AIName, t.before_ScriptName,
       (SELECT COUNT(*) FROM spell_script_names s
        WHERE s.spell_id = 298124
          AND BINARY s.ScriptName = BINARY 'spell_gunker_gooped_bot') AS before_exact_spell_rows
FROM (
    SELECT COUNT(*) AS template_rows, MAX(AIName) AS before_AIName,
           MAX(ScriptName) AS before_ScriptName
    FROM creature_template WHERE entry = 153377
) t;

CREATE TEMPORARY TABLE gunker_fx_bind_pre AS
SELECT checks.*,
       (checks.template_ok = 1 AND checks.sai_ok = 1 AND checks.mapping_ok = 1
        AND checks.neighbors_ok = 1 AND checks.population_ok = 1
        AND checks.static_goop_ok = 1) AS gate_ok
FROM (
    SELECT
        CASE WHEN b.template_rows = 1
                   AND BINARY b.before_AIName = BINARY 'SmartAI'
                   AND b.before_ScriptName IS NOT NULL
                   AND (OCTET_LENGTH(b.before_ScriptName) = 0
                        OR BINARY b.before_ScriptName = BINARY 'npc_mechagon_gunker_goop')
             THEN 1 ELSE 0 END AS template_ok,
        NOT EXISTS (SELECT 1 FROM smart_scripts
                    WHERE entryorguid IN (153377, -153377)) AS sai_ok,
        ((SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) <= 1
         AND NOT EXISTS (SELECT 1 FROM spell_script_names s
                         WHERE s.spell_id = 298124
                           AND (s.ScriptName IS NULL
                                OR BINARY s.ScriptName <> BINARY 'spell_gunker_gooped_bot'))
         AND NOT EXISTS (SELECT 1 FROM spell_script_names WHERE spell_id = -298124)) AS mapping_ok,
        NOT EXISTS (SELECT 1 FROM spell_script_names
                    WHERE spell_id IN (298125, -298125, 298259, -298259)) AS neighbors_ok,
        ((SELECT COUNT(*) FROM (
              SELECT id FROM creature
              WHERE map = 2097
                AND id IN (150168, 150222, 154741, 154744, 154746, 154758, 154759)
              GROUP BY id HAVING COUNT(*) = 1
          ) population) = 7) AS population_ok,
        NOT EXISTS (SELECT 1 FROM creature WHERE id = 153377) AS static_goop_ok
    FROM gunker_fx_bind_before b
) checks;

-- Initial gate and every failed category: 0 means that category failed.
SELECT p.*,
       CASE WHEN p.gate_ok = 0 THEN 'fail'
            WHEN BINARY b.before_ScriptName = BINARY 'npc_mechagon_gunker_goop'
                 AND b.before_exact_spell_rows = 1 THEN 'noop'
            ELSE 'apply' END AS initial_action
FROM gunker_fx_bind_pre p CROSS JOIN gunker_fx_bind_before b;

-- Save this result for rollback BEFORE the temporary tables are dropped.
-- HEX plus explicit NULL/length fields distinguish absent/NULL/empty/name bytes.
SELECT 153377 AS entry, b.template_rows AS before_template_rows,
       b.before_AIName, HEX(b.before_AIName) AS before_AIName_hex,
       b.before_ScriptName, b.before_ScriptName IS NULL AS before_ScriptName_is_null,
       OCTET_LENGTH(b.before_ScriptName) AS before_ScriptName_bytes,
       HEX(b.before_ScriptName) AS before_ScriptName_hex,
       298124 AS spell_id, 'spell_gunker_gooped_bot' AS exact_spell_script,
       b.before_exact_spell_rows
FROM gunker_fx_bind_before b;

-- entry is the creature_template primary key; the live row predicate below
-- checks its original values again without a target-table self-subquery.
UPDATE creature_template ct
JOIN gunker_fx_bind_pre p ON p.gate_ok = 1
SET ct.ScriptName = 'npc_mechagon_gunker_goop'
WHERE ct.entry = 153377
  AND BINARY ct.AIName = BINARY 'SmartAI'
  AND ct.ScriptName IS NOT NULL AND OCTET_LENGTH(ct.ScriptName) = 0
  AND NOT EXISTS (SELECT 1 FROM smart_scripts WHERE entryorguid IN (153377, -153377))
  AND (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) <= 1
  AND NOT EXISTS (SELECT 1 FROM spell_script_names s
                  WHERE s.spell_id = 298124
                    AND (s.ScriptName IS NULL
                         OR BINARY s.ScriptName <> BINARY 'spell_gunker_gooped_bot'))
  AND NOT EXISTS (SELECT 1 FROM spell_script_names WHERE spell_id = -298124)
  AND NOT EXISTS (SELECT 1 FROM spell_script_names
                  WHERE spell_id IN (298125, -298125, 298259, -298259))
  AND (SELECT COUNT(*) FROM (
           SELECT id FROM creature
           WHERE map = 2097
             AND id IN (150168, 150222, 154741, 154744, 154746, 154758, 154759)
           GROUP BY id HAVING COUNT(*) = 1
       ) population) = 7
  AND NOT EXISTS (SELECT 1 FROM creature WHERE id = 153377);
SET @gunker_fx_template_rows = ROW_COUNT();

INSERT INTO spell_script_names (spell_id, ScriptName)
SELECT 298124, 'spell_gunker_gooped_bot'
FROM gunker_fx_bind_pre p
JOIN creature_template ct ON ct.entry = 153377
WHERE p.gate_ok = 1
  AND (SELECT COUNT(*) FROM creature_template WHERE entry = 153377) = 1
  AND BINARY ct.AIName = BINARY 'SmartAI'
  AND BINARY ct.ScriptName = BINARY 'npc_mechagon_gunker_goop'
  AND NOT EXISTS (SELECT 1 FROM smart_scripts WHERE entryorguid IN (153377, -153377))
  AND (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) <= 1
  AND NOT EXISTS (SELECT 1 FROM spell_script_names s
                  WHERE s.spell_id = 298124
                    AND (s.ScriptName IS NULL
                         OR BINARY s.ScriptName <> BINARY 'spell_gunker_gooped_bot'))
  AND NOT EXISTS (SELECT 1 FROM spell_script_names WHERE spell_id = -298124)
  AND NOT EXISTS (SELECT 1 FROM spell_script_names
                  WHERE spell_id IN (298125, -298125, 298259, -298259))
  AND (SELECT COUNT(*) FROM (
           SELECT id FROM creature
           WHERE map = 2097
             AND id IN (150168, 150222, 154741, 154744, 154746, 154758, 154759)
           GROUP BY id HAVING COUNT(*) = 1
       ) population) = 7
  AND NOT EXISTS (SELECT 1 FROM creature WHERE id = 153377)
  AND NOT EXISTS (SELECT 1 FROM spell_script_names s
                  WHERE s.spell_id = 298124
                    AND BINARY s.ScriptName = BINARY 'spell_gunker_gooped_bot');
SET @gunker_fx_spell_rows = ROW_COUNT();

-- Re-read both targets and ALL conflict/population guards for final accounting.
-- fail includes a partial binding and a desired final state with unexpected counts;
-- neither is reported as success. ROW_COUNT values are saved actual DML values.
SELECT
    CASE
        WHEN p.gate_ok = 0 THEN 'fail'
        WHEN a.after_template_rows <> 1 OR a.after_target_template_rows <> 1
          OR a.after_spell_rows <> 1 OR a.after_exact_spell_rows <> 1
          OR a.after_negative_rank_rows <> 0 OR a.after_neighbor_rows <> 0
          OR a.after_sai_rows <> 0 OR a.after_single_population_entries <> 7
          OR a.after_static_goop_rows <> 0 THEN 'fail'
        WHEN @gunker_fx_template_rows <> CASE
                 WHEN b.before_ScriptName IS NOT NULL AND OCTET_LENGTH(b.before_ScriptName) = 0
                 THEN 1 ELSE 0 END
          OR @gunker_fx_spell_rows <> 1 - b.before_exact_spell_rows THEN 'fail'
        WHEN @gunker_fx_template_rows = 0 AND @gunker_fx_spell_rows = 0 THEN 'noop'
        ELSE 'apply'
    END AS result,
    CASE
        WHEN p.gate_ok = 0 THEN 'initial gate failed; both writes blocked'
        WHEN a.after_template_rows <> 1 OR a.after_target_template_rows <> 1
          OR a.after_spell_rows <> 1 OR a.after_exact_spell_rows <> 1
          OR a.after_negative_rank_rows <> 0 OR a.after_neighbor_rows <> 0
          OR a.after_sai_rows <> 0 OR a.after_single_population_entries <> 7
          OR a.after_static_goop_rows <> 0 THEN 'final guard/target failed; inspect partial completion'
        WHEN @gunker_fx_template_rows <> CASE
                 WHEN b.before_ScriptName IS NOT NULL AND OCTET_LENGTH(b.before_ScriptName) = 0
                 THEN 1 ELSE 0 END
          OR @gunker_fx_spell_rows <> 1 - b.before_exact_spell_rows
            THEN 'row accounting differs from before; inspect concurrent/partial changes'
        ELSE 'targets and guards verified; online loading not verified'
    END AS detail,
    p.*,
    b.template_rows AS before_template_rows, b.before_AIName, b.before_ScriptName,
    HEX(b.before_ScriptName) AS before_ScriptName_hex, b.before_exact_spell_rows,
    a.*,
    @gunker_fx_template_rows AS template_ROW_COUNT,
    @gunker_fx_spell_rows AS spell_ROW_COUNT
FROM gunker_fx_bind_pre p
CROSS JOIN gunker_fx_bind_before b
CROSS JOIN (
    SELECT t.*,
           HEX(t.after_AIName) AS after_AIName_hex,
           t.after_ScriptName IS NULL AS after_ScriptName_is_null,
           OCTET_LENGTH(t.after_ScriptName) AS after_ScriptName_bytes,
           HEX(t.after_ScriptName) AS after_ScriptName_hex,
           (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) AS after_spell_rows,
           (SELECT COUNT(*) FROM spell_script_names s
            WHERE s.spell_id = 298124
              AND BINARY s.ScriptName = BINARY 'spell_gunker_gooped_bot') AS after_exact_spell_rows,
           (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298124) AS after_negative_rank_rows,
           (SELECT COUNT(*) FROM spell_script_names
            WHERE spell_id IN (298125, -298125, 298259, -298259)) AS after_neighbor_rows,
           (SELECT COUNT(*) FROM smart_scripts
            WHERE entryorguid IN (153377, -153377)) AS after_sai_rows,
           (SELECT COUNT(*) FROM (
                SELECT id FROM creature
                WHERE map = 2097
                  AND id IN (150168, 150222, 154741, 154744, 154746, 154758, 154759)
                GROUP BY id HAVING COUNT(*) = 1
            ) population) AS after_single_population_entries,
           (SELECT COUNT(*) FROM creature WHERE id = 153377) AS after_static_goop_rows
    FROM (
        SELECT COUNT(*) AS after_template_rows,
               COUNT(CASE WHEN BINARY AIName = BINARY 'SmartAI'
                               AND BINARY ScriptName = BINARY 'npc_mechagon_gunker_goop'
                          THEN 1 END) AS after_target_template_rows,
               MAX(AIName) AS after_AIName, MAX(ScriptName) AS after_ScriptName
        FROM creature_template WHERE entry = 153377
    ) t
) a;

-- Precise rollback RULES ONLY; no rollback is generated/executed by this file.
-- Use the saved before/result outputs from THIS execution, never an inferred old
-- value, a later rerun's snapshot, or the temporary tables after they are dropped.
-- Template: eligible only if before_template_rows=1, before_AIName byte-exact
-- SmartAI, before_ScriptName non-NULL with OCTET_LENGTH=0, and this run's saved
-- template_ROW_COUNT=1. Recheck current entry=153377, BINARY AIName=BINARY 'SmartAI'
-- AND BINARY ScriptName=BINARY 'npc_mechagon_gunker_goop'; only SET ScriptName=''.
-- Do not restore if before already had the target, was missing/NULL/unknown, this
-- run did not update it, or current names changed. Do not change AIName / SAI.
-- Mapping: eligible only if before_exact_spell_rows=0 and this run's saved
-- spell_ROW_COUNT=1. Recheck the current exact pair; delete ONLY spell_id=298124
-- AND BINARY ScriptName=BINARY 'spell_gunker_gooped_bot'. All other names, negative
-- ranks, 298125/298259 pairs remain untouched. If before_exact_spell_rows=1, or the
-- saved before/count evidence is missing, do not delete. If current bindings have
-- changed, stop for review; do not reconstruct or remove someone else's mapping.
-- Rollback needs separate authorization and the same no-concurrent-writer window.

DROP TEMPORARY TABLE IF EXISTS gunker_fx_bind_pre, gunker_fx_bind_before;
