#!/usr/bin/env bash
set -euo pipefail
D="docker compose exec -T db"

$D pg_dump -U postgres -Fc -d retailops -f /backups/retail_admin.dump
$D pg_restore -l /backups/retail_admin.dump > /dev/null && echo "Dump lisible"

$D psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS retail_restore_check;"
$D psql -U postgres -d postgres -c "CREATE DATABASE retail_restore_check;"
$D pg_restore -U postgres -d retail_restore_check --exit-on-error /backups/retail_admin.dump

# Une session ne peut interroger qu'une base : on compare donc deux requêtes séparées
for t in customers products orders order_items; do
    a=$($D psql -U postgres -d retailops            -Atc "SELECT count(*) FROM retail.$t")
    b=$($D psql -U postgres -d retail_restore_check -Atc "SELECT count(*) FROM retail.$t")
    printf '%-12s source=%s restauree=%s %s\n' "$t" "$a" "$b" "$([ "$a" = "$b" ] && echo OK || echo ECART)"
done | tee evidence/restore_report.txt