-- RetailOps — Diagnostic d'un verrou entre deux sessions - l'exécuter pendant que la session 2 est bloquée.

\set ON_ERROR_STOP on

\echo '--- Diagnostic des sessions actives ---'

SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    wait_event_type,
    wait_event,
    xact_start,
    query_start,
    left(query, 120) AS requete
FROM pg_stat_activity
WHERE datname = current_database()
    AND pid <> pg_backend_pid()
ORDER BY backend_start;

\echo '--- Verrous sur les relations ---'

SELECT
    l.pid,
    a.usename,
    a.state,
    l.locktype,
    l.relation::regclass AS table_concernee,
    l.mode,
    l.granted,
    l.waitstart,
    left(a.query, 120) AS requete
FROM pg_locks l
JOIN pg_stat_activity a ON a.pid = l.pid
WHERE l.relation IS NOT NULL
ORDER BY l.waitstart NULLS FIRST, l.pid;

\echo '--- Interprétation ---'
\echo 'Une session avec state = idle in transaction conserve un verrou.'
\echo 'Une session avec wait_event_type = Lock et granted = false attend ce verrou.'