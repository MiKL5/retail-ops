# Supervision — RetailOps
<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-4169E1?logo=postgresql&logoColor=white) ![SQL](https://img.shields.io/badge/SQL-requ%C3%AAtes%20de%20supervision-336791) ![Observabilit%C3%A9](https://img.shields.io/badge/observabilit%C3%A9-seuils%20d%27alerte-orange)

</div>

## Métriques suivies
Domaine | Source | Indicateur
---|---|---
Connexions | `pg_stat_activity` | Nombre de sessions client / `max_connections` ; sessions `idle in transaction`
Verrous | `pg_stat_activity`, `pg_blocking_pids()`, `pg_locks` | Sessions bloquées, durée d'attente, bloqueur
Deadlocks | `pg_stat_database.deadlocks` | Compteur cumulé (suivre sa variation)
Volume | `pg_database_size()`, `pg_total_relation_size()` | Taille base / tables / index, croissance par jour
VACUUM | `pg_stat_user_tables` | `n_dead_tup`, % de lignes mortes, `last_autovacuum`
Requêtes lentes | `pg_stat_statements`, `log_min_duration_statement = 250` | Temps moyen et total par requête
Archivage WAL | `pg_stat_archiver` | `failed_count`, `last_archived_time`
Cache | `pg_stat_database` | `blks_hit / (blks_hit + blks_read)`
## Seuils d'alerte
Indicateur | Seuil d'alerte | Action proposée
---|---:|---
**Transaction ouverte** | > 5 minutes | Identifier la session (`pg_stat_activity`), contacter son propriétaire, puis décider d'un `ROLLBACK` ou d'une terminaison contrôlée (`pg_terminate_backend`) pour libérer les verrous.
**Connexions utilisées** | > 80 % (soit > 80/100 connexions) pendant 5 min | Conserver une marge pour l'administration et les pics de charge ; auditer l'application pour traquer les fuites de connexions (absence de fermeture de pool).
**Session bloquée par un verrou** | Attente > 30 secondes | Identifier la session bloqueuse à l'origine de la contention et résoudre l'incident transactionnel pour éviter le dépassement des timeouts HTTP applicatifs.
**Lignes mortes** | > 20 % sur une table de plus de 10 000 lignes | Vérifier le comportement de l'autovacuum, lancer un `VACUUM ANALYZE` manuel si nécessaire et investiguer les processus d'écritures massives ou répétées.
**Archivage WAL** | `failed_count` en augmentation ou dernier archivage > 5 min | Résoudre immédiatement le problème d'accès au répertoire d'archive (`wal_archive`) pour préserver le RPO et garantir la fabricabilité du PITR.
**Requête lente** | `mean_exec_time` > 500 ms pour une requête appelée > 100 fois | Analyser le plan d'exécution (`EXPLAIN ANALYZE`) et proposer une optimisation (indexation ciblée ou réécriture de la requête).
## Limites opérationnelles
Ces seuils et indicateurs sont informatifs pour un environnement de développement ou un premier niveau d'exploitation locale.  
En production, ils doivent être finement calibrés après une phase d'observation de la charge réelle et intégrés dans une plateforme de supervision centralisée.