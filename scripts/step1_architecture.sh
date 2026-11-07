#!/usr/bin/env bash
# Étape 1 — Démarrer l'instance et prouver version, fichiers de config, volumes
. "$(dirname "$0")/lib.sh"
$DC up -d --build --wait
{
  echo "### $(date -u +%FT%TZ) — Architecture"
  echo "--- docker compose ps"; $DC ps
  echo "--- version"; psqla -d retailops -Atc "SELECT version();"
  echo "--- fichiers et répertoires"
  psqla -d retailops -Atc "SHOW config_file; SHOW hba_file; SHOW data_directory;"
  echo "--- paramètres clés"
  psqla -d retailops -Atc "SHOW listen_addresses; SHOW port; SHOW password_encryption; SHOW ssl; SHOW shared_preload_libraries; SHOW archive_mode;"
  echo "--- bases et schémas"
  psqla -d retailops -c "\l" -c "\dn"
  echo "--- volumes Docker (persistance)"
  docker volume ls --filter name=retailops
  docker volume inspect retailops_pgdata --format 'pgdata -> {{.Mountpoint}}'
  echo "--- port publié (127.0.0.1 uniquement)"; docker port retailops-db
} 2>&1 | tee evidence/01_architecture.txt
