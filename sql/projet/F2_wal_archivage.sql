SHOW archive_mode;
SHOW archive_command;

SELECT archived_count, failed_count, last_archived_wal, last_archived_time
FROM pg_stat_archiver;

-- Explication PITR : les WAL permettent de rejouer les transactions
-- jusqu'à un point dans le temps (recovery_target_time).