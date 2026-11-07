#!/usr/bin/env bash
# Étape 6 — Dump custom, restauration sur retail_restore_check, comparaison, archivage WAL
. "$(dirname "$0")/lib.sh"
DUMP=backups/retail_admin.dump

{
  echo "### $(date -u +%FT%TZ) — Sauvegarde logique (format custom)"
  $DC exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" db pg_dump -U postgres -d retailops -Fc > "$DUMP"
  ls -l "$DUMP"
  echo "--- Sommaire du dump (pg_restore -l) = le fichier est lisible"
  $DC exec -T db pg_restore -l < "$DUMP" | sed -n '1,40p'
} 2>&1 | tee evidence/06_dump.txt

{
  echo "### $(date -u +%FT%TZ) — Restauration sur une base DISTINCTE"
  psqla -d postgres -c "DROP DATABASE IF EXISTS retail_restore_check;" -c "CREATE DATABASE retail_restore_check;"
  START=$SECONDS
  $DC exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" db pg_restore -U postgres -d retail_restore_check --exit-on-error < "$DUMP"
  echo "Durée de restauration mesurée : $((SECONDS-START)) s  (base de ~quelques Mo ; sert de base à l'estimation du RTO)"
  echo; echo "--- SOURCE (retailops)";                psqla -d retailops            -At -F ' = ' -f /sql/11_counts.sql | tee /tmp/src.txt
  echo; echo "--- RESTAURÉE (retail_restore_check)";  psqla -d retail_restore_check -At -F ' = ' -f /sql/11_counts.sql | tee /tmp/dst.txt
  echo
  # /tmp ici = hôte ; les fichiers ont été écrits par tee ci-dessus
  if diff -q /tmp/src.txt /tmp/dst.txt >/dev/null; then echo "RÉSULTAT : IDENTIQUE (lignes et CA total)"; else echo "RÉSULTAT : DIFFÉRENCES !"; diff /tmp/src.txt /tmp/dst.txt || true; fi
} 2>&1 | tee evidence/06_restauration.txt

{
  echo "### $(date -u +%FT%TZ) — Archivage WAL"
  psqla -d retailops -c "CHECKPOINT;" -c "SELECT pg_switch_wal();" >/dev/null
  sleep 3
  psqla -d retailops -c "SHOW archive_mode;" -c "SHOW archive_command;" -c "SHOW archive_timeout;" -c "SHOW wal_level;"
  psqla -d retailops -x -c "SELECT * FROM pg_stat_archiver;"
  echo "--- Fichiers archivés (volume walarchive)"
  $DC exec -T db sh -c 'ls -l /var/lib/postgresql/wal_archive | tail -10; echo; echo "Segments archivés : $(ls /var/lib/postgresql/wal_archive | wc -l)"'
} 2>&1 | tee evidence/06_wal.txt
