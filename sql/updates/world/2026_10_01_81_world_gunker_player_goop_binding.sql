-- BFA 8.3.7.35662 / Gunker player goop lifecycle, frozen module Task5.
-- Generated migration text only. Not executed, runtime verification pending.
-- Permanent writes: ONLY +298125 then +298259 in spell_script_names.
-- Old80 / creature_template / smart_scripts / creature are read-only here.

-- 1. FUTURE MAINTENANCE PROCEDURE (comments, not execution or authorization).
-- First establish no concurrent binding writers and no managed live Aura/Spell.
-- Save actual database/version/table engines, binary identity and ALL result sets.
-- Fresh-check both signs of the new targets. Only when BOTH new targets are wholly
-- empty may old 2026_09_30_80 run under ITS OWN guards as apply/noop; export its
-- ORIGINAL before and both actual ROW_COUNT values before its TEMP tables drop.
-- If ANY new mapping already exists, NEVER run old80 backwards: require its old
-- template/+298124 binding to be complete directly. Incomplete old state is fail;
-- isolate and investigate, never delete new mappings to force old80 to run.
-- After new bindings exist, old80's neighbors-zero guard SHOULD fail. A complete
-- new-version rerun uses ONLY this new migration's idempotent verification.
-- Prior SELECT-only preparation showed MySQL 8.4.10 and all four relevant tables
-- MyISAM. It is not maintenance isolation or migration approval. These two DML
-- statements are NON-ATOMIC; do not rely on cross-table transaction rollback.
-- Second-step failure may leave the first mapping: retain evidence, result fail,
-- prohibit hot running a partial pair. No online half-unload/half-mapping switch.

-- 2. Preserve complete ORIGINAL rows and explicit NULL/byte/HEX evidence, without
-- MAX collapsing duplicates. Independent gunker_player_bind_* TEMP names only.
-- Maintenance isolation is required for the following separate snapshot reads.
DROP TEMPORARY TABLE IF EXISTS
    gunker_player_bind_pre,
    gunker_player_bind_before,
    gunker_player_bind_before_spell,
    gunker_player_bind_before_template,
    gunker_player_bind_before_sai,
    gunker_player_bind_before_static,
    gunker_player_bind_before_population,
    gunker_player_bind_before_spawns;

CREATE TEMPORARY TABLE gunker_player_bind_before_spell AS
SELECT s.*, s.ScriptName IS NULL AS before_ScriptName_is_null,
       OCTET_LENGTH(s.ScriptName) AS before_ScriptName_bytes,
       HEX(s.ScriptName) AS before_ScriptName_hex
FROM spell_script_names s
WHERE s.spell_id IN (298125, -298125, 298259, -298259, 298124, -298124);

CREATE TEMPORARY TABLE gunker_player_bind_before_template AS
SELECT ct.*, ct.AIName IS NULL AS before_AIName_is_null,
       OCTET_LENGTH(ct.AIName) AS before_AIName_bytes,
       HEX(ct.AIName) AS before_AIName_hex,
       ct.ScriptName IS NULL AS before_ScriptName_is_null,
       OCTET_LENGTH(ct.ScriptName) AS before_ScriptName_bytes,
       HEX(ct.ScriptName) AS before_ScriptName_hex
FROM creature_template ct WHERE ct.entry = 153377;

-- All source_type values and both entryorguid signs; no source_type filter.
CREATE TEMPORARY TABLE gunker_player_bind_before_sai AS
SELECT s.* FROM smart_scripts s WHERE s.entryorguid IN (153377, -153377);

-- All maps, not only 2097.
CREATE TEMPORARY TABLE gunker_player_bind_before_static AS
SELECT c.* FROM creature c WHERE c.id = 153377;

-- Explicit seven per-entry counts include zero/missing entries.
CREATE TEMPORARY TABLE gunker_player_bind_before_population AS
SELECT expected.id, COUNT(c.id) AS before_spawn_count
FROM (
    SELECT 150168 AS id UNION ALL SELECT 150222 UNION ALL SELECT 154741
    UNION ALL SELECT 154744 UNION ALL SELECT 154746 UNION ALL SELECT 154758
    UNION ALL SELECT 154759
) expected
LEFT JOIN creature c ON c.map = 2097 AND c.id = expected.id
GROUP BY expected.id;

-- Preserve actual spawn columns (including position) and template script bytes
-- for read-only neighbor inspection. No bot ScriptName/position/population writes.
CREATE TEMPORARY TABLE gunker_player_bind_before_spawns AS
SELECT c.*, ct.AIName AS before_template_AIName,
       ct.AIName IS NULL AS before_template_AIName_is_null,
       OCTET_LENGTH(ct.AIName) AS before_template_AIName_bytes,
       HEX(ct.AIName) AS before_template_AIName_hex,
       ct.ScriptName AS before_template_ScriptName,
       ct.ScriptName IS NULL AS before_template_ScriptName_is_null,
       OCTET_LENGTH(ct.ScriptName) AS before_template_ScriptName_bytes,
       HEX(ct.ScriptName) AS before_template_ScriptName_hex
FROM creature c LEFT JOIN creature_template ct ON ct.entry = c.id
WHERE c.map = 2097
  AND c.id IN (150168, 150222, 154741, 154744, 154746, 154758, 154759);

-- One accounting row even for absent targets, alongside ALL raw rows above.
CREATE TEMPORARY TABLE gunker_player_bind_before AS
SELECT
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125) AS summon_total,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125
          AND ScriptName IS NOT NULL
          AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player_summon')
          AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player_summon') AS summon_exact,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298125) AS summon_negative,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259) AS aura_total,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259
          AND ScriptName IS NOT NULL
          AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player')
          AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player') AS aura_exact,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298259) AS aura_negative,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) AS bot_total,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124
          AND ScriptName IS NOT NULL
          AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_bot')
          AND BINARY ScriptName = BINARY 'spell_gunker_gooped_bot') AS bot_exact,
    (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298124) AS bot_negative,
    (SELECT COUNT(*) FROM creature_template WHERE entry = 153377) AS template_total,
    (SELECT COUNT(*) FROM creature_template WHERE entry = 153377
          AND AIName IS NOT NULL AND ScriptName IS NOT NULL
          AND OCTET_LENGTH(AIName) = OCTET_LENGTH('SmartAI')
          AND BINARY AIName = BINARY 'SmartAI'
          AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('npc_mechagon_gunker_goop')
          AND BINARY ScriptName = BINARY 'npc_mechagon_gunker_goop') AS template_exact,
    (SELECT COUNT(*) FROM smart_scripts WHERE entryorguid IN (153377, -153377)) AS sai_total,
    (SELECT COUNT(*) FROM creature WHERE id = 153377) AS static_goop_total,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150168) AS population_150168,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150222) AS population_150222,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154741) AS population_154741,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154744) AS population_154744,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154746) AS population_154746,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154758) AS population_154758,
    (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154759) AS population_154759;

-- 3. Simultaneous initial gate: each new positive ID is empty or exactly ONE
-- byte/length-exact own row. NULL/case/trailing/foreign/duplicate all fail.
-- All three negative IDs must be empty; old +298124 must be exactly one own row;
-- old template must be exactly one SmartAI/npc_mechagon_gunker_goop byte pair.
-- SAI +/-153377 all source types zero; static 153377 all maps zero; seven each one.
CREATE TEMPORARY TABLE gunker_player_bind_pre AS
SELECT checks.*,
       (checks.summon_mapping_ok = 1 AND checks.aura_mapping_ok = 1
        AND checks.bot_mapping_ok = 1 AND checks.template_ok = 1
        AND checks.sai_ok = 1 AND checks.static_goop_ok = 1
        AND checks.population_ok = 1) AS initial_gate_ok
FROM (
    SELECT
        (b.summon_total <= 1 AND b.summon_exact = b.summon_total
         AND b.summon_negative = 0) AS summon_mapping_ok,
        (b.aura_total <= 1 AND b.aura_exact = b.aura_total
         AND b.aura_negative = 0) AS aura_mapping_ok,
        (b.bot_total = 1 AND b.bot_exact = 1 AND b.bot_negative = 0) AS bot_mapping_ok,
        (b.template_total = 1 AND b.template_exact = 1) AS template_ok,
        (b.sai_total = 0) AS sai_ok,
        (b.static_goop_total = 0) AS static_goop_ok,
        (b.population_150168 = 1
         AND b.population_150222 = 1
         AND b.population_154741 = 1
         AND b.population_154744 = 1
         AND b.population_154746 = 1
         AND b.population_154758 = 1
         AND b.population_154759 = 1) AS population_ok
    FROM gunker_player_bind_before b
) checks;

-- EXPORT every before row/count and gate category now; save empty result sets too.
SELECT * FROM gunker_player_bind_before_spell ORDER BY spell_id, before_ScriptName_hex;
SELECT * FROM gunker_player_bind_before_template;
SELECT * FROM gunker_player_bind_before_sai ORDER BY entryorguid, source_type;
SELECT * FROM gunker_player_bind_before_static ORDER BY map, guid;
SELECT * FROM gunker_player_bind_before_population ORDER BY id;
SELECT * FROM gunker_player_bind_before_spawns ORDER BY id, guid;
SELECT b.*, p.*,
       CASE WHEN p.initial_gate_ok = 0 THEN 'fail'
            WHEN b.summon_exact = 1 AND b.aura_exact = 1 THEN 'noop'
            ELSE 'apply' END AS initial_action
FROM gunker_player_bind_before b CROSS JOIN gunker_player_bind_pre p;

-- 4. Physical write order: summon +298125, then aura +298259.
-- Every INSERT rechecks ALL live guards; the frozen initial gate never reopens.
-- Each derived live read uses real base tables, not the before snapshot. The other
-- target may already be own, but foreign/negative/duplicate is never allowed.
INSERT INTO spell_script_names (spell_id, ScriptName)
SELECT 298125, 'spell_gunker_gooped_player_summon'
FROM gunker_player_bind_pre p
CROSS JOIN (
    SELECT
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125) AS summon_total,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125
              AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player_summon')
              AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player_summon') AS summon_exact,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298125) AS summon_negative,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259) AS aura_total,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259
              AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player')
              AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player') AS aura_exact,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298259) AS aura_negative,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) AS bot_total,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124
              AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_bot')
              AND BINARY ScriptName = BINARY 'spell_gunker_gooped_bot') AS bot_exact,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298124) AS bot_negative,
        (SELECT COUNT(*) FROM creature_template WHERE entry = 153377) AS template_total,
        (SELECT COUNT(*) FROM creature_template WHERE entry = 153377
              AND AIName IS NOT NULL AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(AIName) = OCTET_LENGTH('SmartAI')
              AND BINARY AIName = BINARY 'SmartAI'
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('npc_mechagon_gunker_goop')
              AND BINARY ScriptName = BINARY 'npc_mechagon_gunker_goop') AS template_exact,
        (SELECT COUNT(*) FROM smart_scripts WHERE entryorguid IN (153377, -153377)) AS sai_total,
        (SELECT COUNT(*) FROM creature WHERE id = 153377) AS static_goop_total,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150168) AS population_150168,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150222) AS population_150222,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154741) AS population_154741,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154744) AS population_154744,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154746) AS population_154746,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154758) AS population_154758,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154759) AS population_154759
) live
WHERE p.initial_gate_ok = 1
  AND live.summon_total <= 1
  AND live.summon_exact = live.summon_total
  AND live.summon_negative = 0
  AND live.aura_total <= 1
  AND live.aura_exact = live.aura_total
  AND live.aura_negative = 0
  AND live.bot_total = 1
  AND live.bot_exact = 1
  AND live.bot_negative = 0
  AND live.template_total = 1
  AND live.template_exact = 1
  AND live.sai_total = 0
  AND live.static_goop_total = 0
  AND live.population_150168 = 1
  AND live.population_150222 = 1
  AND live.population_154741 = 1
  AND live.population_154744 = 1
  AND live.population_154746 = 1
  AND live.population_154758 = 1
  AND live.population_154759 = 1
  AND live.summon_total = 0;
SET @gunker_player_summon_rows = ROW_COUNT();

INSERT INTO spell_script_names (spell_id, ScriptName)
SELECT 298259, 'spell_gunker_gooped_player'
FROM gunker_player_bind_pre p
CROSS JOIN (
    SELECT
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125) AS summon_total,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125
              AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player_summon')
              AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player_summon') AS summon_exact,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298125) AS summon_negative,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259) AS aura_total,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259
              AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player')
              AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player') AS aura_exact,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298259) AS aura_negative,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) AS bot_total,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124
              AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_bot')
              AND BINARY ScriptName = BINARY 'spell_gunker_gooped_bot') AS bot_exact,
        (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298124) AS bot_negative,
        (SELECT COUNT(*) FROM creature_template WHERE entry = 153377) AS template_total,
        (SELECT COUNT(*) FROM creature_template WHERE entry = 153377
              AND AIName IS NOT NULL AND ScriptName IS NOT NULL
              AND OCTET_LENGTH(AIName) = OCTET_LENGTH('SmartAI')
              AND BINARY AIName = BINARY 'SmartAI'
              AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('npc_mechagon_gunker_goop')
              AND BINARY ScriptName = BINARY 'npc_mechagon_gunker_goop') AS template_exact,
        (SELECT COUNT(*) FROM smart_scripts WHERE entryorguid IN (153377, -153377)) AS sai_total,
        (SELECT COUNT(*) FROM creature WHERE id = 153377) AS static_goop_total,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150168) AS population_150168,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150222) AS population_150222,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154741) AS population_154741,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154744) AS population_154744,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154746) AS population_154746,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154758) AS population_154758,
        (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154759) AS population_154759
) live
WHERE p.initial_gate_ok = 1
  AND live.summon_total <= 1
  AND live.summon_exact = live.summon_total
  AND live.summon_negative = 0
  AND live.aura_total <= 1
  AND live.aura_exact = live.aura_total
  AND live.aura_negative = 0
  AND live.bot_total = 1
  AND live.bot_exact = 1
  AND live.bot_negative = 0
  AND live.template_total = 1
  AND live.template_exact = 1
  AND live.sai_total = 0
  AND live.static_goop_total = 0
  AND live.population_150168 = 1
  AND live.population_150222 = 1
  AND live.population_154741 = 1
  AND live.population_154744 = 1
  AND live.population_154746 = 1
  AND live.population_154758 = 1
  AND live.population_154759 = 1
  AND live.summon_total = 1 AND live.summon_exact = 1
  AND live.aura_total = 0;
SET @gunker_player_aura_rows = ROW_COUNT();

-- 5. Re-read ALL final targets/neighbors and require actual count = 1-beforeExact.
-- Only both BEFORE own + both counts zero is complete noop. Filling one/both is
-- apply. Initial/final/count failure is fail, even if final targets happen to exist.
-- Export this final result and both saved actual counts BEFORE any TEMP drop.
SELECT
    CASE WHEN p.initial_gate_ok <> 1 OR f.final_guard_ok <> 1
              OR @gunker_player_summon_rows <> 1 - b.summon_exact
              OR @gunker_player_aura_rows <> 1 - b.aura_exact THEN 'fail'
         WHEN b.summon_exact = 1 AND b.aura_exact = 1
              AND @gunker_player_summon_rows = 0 AND @gunker_player_aura_rows = 0 THEN 'noop'
         ELSE 'apply' END AS result,
    CASE WHEN p.initial_gate_ok <> 1 THEN
              'initial gate failed; both DML blocked; inspect before/gate evidence'
         WHEN f.final_guard_ok <> 1
              OR @gunker_player_summon_rows <> 1 - b.summon_exact
              OR @gunker_player_aura_rows <> 1 - b.aura_exact THEN
              CONCAT('final guard/count fail; partial detail: before summon/aura=',
                     b.summon_total, '/', b.aura_total, '; actual inserted=',
                     @gunker_player_summon_rows, '/', @gunker_player_aura_rows,
                     '; final total/exact summon=', f.summon_total, '/', f.summon_exact,
                     ', aura=', f.aura_total, '/', f.aura_exact,
                     '; isolate; no hot run; preserve evidence for ownership recovery')
         ELSE 'targets/guards/counts verified in SQL only; paired runtime loading pending'
    END AS detail,
    @gunker_player_summon_rows AS summon_ROW_COUNT,
    @gunker_player_aura_rows AS aura_ROW_COUNT,
    1 - b.summon_exact AS expected_summon_ROW_COUNT,
    1 - b.aura_exact AS expected_aura_ROW_COUNT,
    b.summon_total AS before_summon_total,
    b.summon_exact AS before_summon_exact,
    b.summon_negative AS before_summon_negative,
    b.aura_total AS before_aura_total,
    b.aura_exact AS before_aura_exact,
    b.aura_negative AS before_aura_negative,
    b.bot_total AS before_bot_total,
    b.bot_exact AS before_bot_exact,
    b.bot_negative AS before_bot_negative,
    b.template_total AS before_template_total,
    b.template_exact AS before_template_exact,
    b.sai_total AS before_sai_total,
    b.static_goop_total AS before_static_goop_total,
    b.population_150168 AS before_population_150168,
    b.population_150222 AS before_population_150222,
    b.population_154741 AS before_population_154741,
    b.population_154744 AS before_population_154744,
    b.population_154746 AS before_population_154746,
    b.population_154758 AS before_population_154758,
    b.population_154759 AS before_population_154759,
    p.*,
    f.summon_total AS after_summon_total,
    f.summon_exact AS after_summon_exact,
    f.summon_negative AS after_summon_negative,
    f.aura_total AS after_aura_total,
    f.aura_exact AS after_aura_exact,
    f.aura_negative AS after_aura_negative,
    f.bot_total AS after_bot_total,
    f.bot_exact AS after_bot_exact,
    f.bot_negative AS after_bot_negative,
    f.template_total AS after_template_total,
    f.template_exact AS after_template_exact,
    f.sai_total AS after_sai_total,
    f.static_goop_total AS after_static_goop_total,
    f.population_150168 AS after_population_150168,
    f.population_150222 AS after_population_150222,
    f.population_154741 AS after_population_154741,
    f.population_154744 AS after_population_154744,
    f.population_154746 AS after_population_154746,
    f.population_154758 AS after_population_154758,
    f.population_154759 AS after_population_154759,
    f.final_guard_ok
FROM gunker_player_bind_before b
CROSS JOIN gunker_player_bind_pre p
CROSS JOIN (
    SELECT live.*, (
        live.summon_total = 1
        AND live.summon_exact = live.summon_total
        AND live.summon_negative = 0
        AND live.aura_total = 1
        AND live.aura_exact = live.aura_total
        AND live.aura_negative = 0
        AND live.bot_total = 1
        AND live.bot_exact = 1
        AND live.bot_negative = 0
        AND live.template_total = 1
        AND live.template_exact = 1
        AND live.sai_total = 0
        AND live.static_goop_total = 0
        AND live.population_150168 = 1
        AND live.population_150222 = 1
        AND live.population_154741 = 1
        AND live.population_154744 = 1
        AND live.population_154746 = 1
        AND live.population_154758 = 1
        AND live.population_154759 = 1
    ) AS final_guard_ok
    FROM (
        SELECT
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125) AS summon_total,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298125
                  AND ScriptName IS NOT NULL
                  AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player_summon')
                  AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player_summon') AS summon_exact,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298125) AS summon_negative,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259) AS aura_total,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298259
                  AND ScriptName IS NOT NULL
                  AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_player')
                  AND BINARY ScriptName = BINARY 'spell_gunker_gooped_player') AS aura_exact,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298259) AS aura_negative,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124) AS bot_total,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 298124
                  AND ScriptName IS NOT NULL
                  AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('spell_gunker_gooped_bot')
                  AND BINARY ScriptName = BINARY 'spell_gunker_gooped_bot') AS bot_exact,
            (SELECT COUNT(*) FROM spell_script_names WHERE spell_id = -298124) AS bot_negative,
            (SELECT COUNT(*) FROM creature_template WHERE entry = 153377) AS template_total,
            (SELECT COUNT(*) FROM creature_template WHERE entry = 153377
                  AND AIName IS NOT NULL AND ScriptName IS NOT NULL
                  AND OCTET_LENGTH(AIName) = OCTET_LENGTH('SmartAI')
                  AND BINARY AIName = BINARY 'SmartAI'
                  AND OCTET_LENGTH(ScriptName) = OCTET_LENGTH('npc_mechagon_gunker_goop')
                  AND BINARY ScriptName = BINARY 'npc_mechagon_gunker_goop') AS template_exact,
            (SELECT COUNT(*) FROM smart_scripts WHERE entryorguid IN (153377, -153377)) AS sai_total,
            (SELECT COUNT(*) FROM creature WHERE id = 153377) AS static_goop_total,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150168) AS population_150168,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 150222) AS population_150222,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154741) AS population_154741,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154744) AS population_154744,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154746) AS population_154746,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154758) AS population_154758,
            (SELECT COUNT(*) FROM creature WHERE map = 2097 AND id = 154759) AS population_154759
    ) live
) f;

-- 6. PRECISE REVERSE-ORDER RECOVERY RULES ONLY; NO rollback SQL executes here.
-- Retain/export before raw rows/counts, every initial gate, both actual ROW_COUNT
-- values and final result above BEFORE dropping TEMP. Use THIS execution's saved
-- evidence, never a later rerun's before or updates-table/ID-presence inference.
-- Missing/contradictory evidence: STOP, fail; do not infer original ownership.
-- Under maintenance isolation, first inspect BOTH positive target rowsets and
-- negatives. Any foreign/duplicate/NULL/case/trailing change: STOP and report fail.
-- Order is +298259 FIRST, +298125 SECOND. For EACH positive ID, eligibility is
-- before_total=0 AND before_exact=0 AND THIS run's corresponding ROW_COUNT=1.
-- Before-owned rows (before_total=1/before_exact=1) are NEVER removed, including
-- partial-own applies; count=0 is NEVER ownership proof of an inserted row.
-- Before deletion recheck current positive ID total=1, ScriptName non-NULL,
-- OCTET_LENGTH equal to the target literal and BINARY equal to the target literal.
-- 298259 literal: spell_gunker_gooped_player;
-- 298125 literal: spell_gunker_gooped_player_summon.
-- Only that positive spell_id AND that byte/length-exact ScriptName may be removed
-- if eligible; no ABS-based group deletion, no negative deletion, no replacement.
-- If an eligible row is missing/changed/duplicated, STOP, fail; do not continue the
-- other deletion blindly. Recheck again at each step; no transaction rollback claim.
-- Only after BOTH SIGNS of 298125/298259 return to zero may old80 recovery be
-- considered from ITS ORIGINAL saved before/template_ROW_COUNT/spell_ROW_COUNT.
-- Old before-owned template or +298124 remains. No missing-evidence reconstruction.
-- Old80's own exact ownership predicates apply; never restore AIName/SAI, never
-- alter bot ScriptName/position, static NPC or any other column. No rollback run.

-- 7. FUTURE PAIRED RUNTIME CHECKLIST (not Passed by this migration/build).
-- Match binary identity to reviewed source: both new Register calls and actual
-- AddSC_boss_gunker loader invocation; retain old three Creature and bot loaders.
-- Verify raw positive mappings each exclusive, all negative ranks zero; actual
-- enabled=true/Validate success, Aura Load AND Spell Load, real managed Apply ->
-- prepareSeen -> real HIT/concrete-return capture in actual difficulties 2/23/8.
-- updates registration, ID existence, or default creation of G proves NONE of it.
-- Entire disabled class/default G is wiring fail. For noSource/no-token 298125,
-- Spell Load must still succeed and OnPrepare/HIT be no-op, preserving original
-- bot/foreign counts, duration, Source/visual/owner/callback behavior.
-- No half-script unload/mapping hot switch with live managed Aura/Spell.
-- Guard matrix (empty/apply, partial-own/apply, complete/noop, foreign/case/trailing/
-- NULL/duplicate/negative/old-neighbor fail-zero-writes, second-step partial fail),
-- precise recovery, paired loading and client observations remain runtime_pending.

DROP TEMPORARY TABLE IF EXISTS
    gunker_player_bind_pre,
    gunker_player_bind_before,
    gunker_player_bind_before_spell,
    gunker_player_bind_before_template,
    gunker_player_bind_before_sai,
    gunker_player_bind_before_static,
    gunker_player_bind_before_population,
    gunker_player_bind_before_spawns;
