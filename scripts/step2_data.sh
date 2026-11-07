#!/usr/bin/env bash
# Étape 2 — Schéma, chargement des CSV, contrôles, requêtes métier
. "$(dirname "$0")/lib.sh"
{
  echo "### $(date -u +%FT%TZ) — Schéma + chargement"
  psqla -d retailops -f /sql/01_schema.sql
  psqla -d retailops -f /sql/02_load.sql
} 2>&1 | tee evidence/02_load.txt
psqla -d retailops -f /sql/03_controls.sql 2>&1 | tee evidence/02_controles.txt
psqla -d retailops -f /sql/04_business_queries.sql 2>&1 | tee evidence/02_requetes_metier.txt
