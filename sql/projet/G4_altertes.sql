\echo '--- Seuil 1 : transaction ouverte depuis plus de 5 minutes ---'
SELECT pid, usename, state, now() - xact_start AS duree, left(query, 80) AS requete
FROM pg_stat_activity
WHERE datname = current_database()
    AND pid <> pg_backend_pid()
    AND xact_start < now() - interval '5 minutes';

\echo '--- Seuil 2 : plus de 20 % de lignes mortes ---'
SELECT relname, n_live_tup, n_dead_tup,
       round(100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0), 2) AS pct_lignes_mortes
FROM pg_stat_user_tables
WHERE schemaname = 'retail'
    AND n_dead_tup > 50
    AND 100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0) > 20;