-- À exécuter en tant qu'utilisateur disposant d'un accès en lecture aux vues système.

\set ON_ERROR_STOP on
\echo '=== 1. Connexions actives ==='

SELECT
    count(*) FILTER (WHERE state = 'active') AS connexions_actives,
    count(*) FILTER (WHERE state = 'idle') AS connexions_inactives,
    count(*) FILTER (WHERE state = 'idle in transaction') AS transactions_ouvertes,
    count(*) AS total_connexions
FROM pg_stat_activity
WHERE datname = current_database();

\echo '=== 2. Sessions en attente d''un verrou ==='

SELECT
    a.pid,
    a.usename,
    a.state,
    a.wait_event_type,
    a.wait_event,
    a.query_start,
    left(a.query, 120) AS requete
FROM pg_stat_activity a
WHERE a.datname = current_database()
    AND a.wait_event_type = 'Lock'
ORDER BY a.query_start;

\echo '=== 3. Verrous non obtenus ==='

SELECT
    l.pid,
    a.usename,
    l.locktype,
    l.relation::regclass AS table_concernee,
    l.mode,
    l.granted,
    l.waitstart
FROM pg_locks l
JOIN pg_stat_activity a ON a.pid = l.pid
WHERE l.granted = false
ORDER BY l.waitstart;

\echo '=== 4. Tables nécessitant une maintenance ==='

SELECT
    relname AS table_name,
    n_live_tup AS lignes_vivantes,
    n_dead_tup AS lignes_mortes,
    CASE
        WHEN n_live_tup > 0
        THEN round(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 2)
        ELSE 0
    END AS pourcentage_lignes_mortes,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'retail'
ORDER BY n_dead_tup DESC;

\echo '=== 5. Taille des tables et de la base ==='

SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(format('%I.%I', schemaname, relname))) AS taille_totale
FROM pg_stat_user_tables
WHERE schemaname = 'retail'
ORDER BY pg_total_relation_size(format('%I.%I', schemaname, relname)) DESC;

SELECT
    datname AS base,
    pg_size_pretty(pg_database_size(datname)) AS taille_base
FROM pg_database
WHERE datname = current_database();

\echo '=== 6. Requêtes les plus consommatrices ==='

SELECT
    calls,
    round(total_exec_time::numeric, 2) AS temps_total_ms,
    round(mean_exec_time::numeric, 2) AS temps_moyen_ms,
    rows,
    left(query, 120) AS requete
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY total_exec_time DESC
LIMIT 10;

\echo '=== 7. Deadlocks cumulés ==='
SELECT datname, deadlocks, conflicts, xact_commit, xact_rollback
FROM pg_stat_database
WHERE datname = current_database();