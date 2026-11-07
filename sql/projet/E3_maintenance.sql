-- À exécuter à froid, hors transaction (VACUUM refuse de s'exécuter dans un BEGIN).

\set ON_ERROR_STOP on

\echo '--- Maintenance : nettoyage et statistiques à jour ---'
VACUUM (VERBOSE, ANALYZE) retail.customers;
VACUUM (VERBOSE, ANALYZE) retail.products;
VACUUM (VERBOSE, ANALYZE) retail.orders;
VACUUM (VERBOSE, ANALYZE) retail.order_items;

\echo '--- Tailles et état des tables ---'
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS taille_totale,
       n_live_tup, n_dead_tup,
       last_vacuum, last_autovacuum, last_analyze
FROM   pg_stat_user_tables
WHERE  schemaname = 'retail'
ORDER BY n_dead_tup DESC, relname;

\echo '--- Taille de la base ---'
SELECT datname AS base,
       pg_size_pretty(pg_database_size(datname)) AS taille_base
FROM   pg_database
WHERE  datname = current_database();

\echo '--- Tablespaces ---'
-- Le tablespace par défaut (pg_default) suffit en local.
-- En production un tablespace séparé pour isoler les entrées/sorties  (par exemple, les index ou les gros volumes sur un autre disque).
SELECT spcname FROM pg_tablespace;