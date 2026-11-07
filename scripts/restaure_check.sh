set -euo pipefail
D="docker compose exec -T db"

$D psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS retail_restore_check;"
$D psql -U postgres -d postgres -c "CREATE DATABASE retail_restore_check;"

# Les rôles ne sont pas contenus dans le dump d'une base : ils existent déjà, donc pas de --no-owner nécessaire ici.
$D pg_restore -U postgres -d retail_restore_check --exit-on-error /backups/retail_admin.dump

# Comparaison des volumes
for t in customers products orders order_items; do
    a=$($D psql -U postgres -d retailops           -Atc "SELECT count(*) FROM retail.$t")
    b=$($D psql -U postgres -d retail_restore_check -Atc "SELECT count(*) FROM retail.$t")
    printf "%-12s source=%s restaurée=%s %s\n" "$t" "$a" "$b" "$([ "$a" = "$b" ] && echo OK || echo ECART)"
done | tee evidence/restore_report.txt