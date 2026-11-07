\echo '--- Version ---'
SELECT version();
\echo '--- Fichiers et répertoires ---'
SHOW config_file;
SHOW hba_file;
SHOW data_directory;
SHOW port;
SHOW ssl;
\echo '--- Bases et schémas ---'
SELECT datname FROM pg_database WHERE NOT datistemplate;
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'retail';