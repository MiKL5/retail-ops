#!/usr/bin/env bash
set -euo pipefail

mkdir -p evidence

psql_db() {
    docker compose exec -T --user postgres db \
        psql -X -U postgres -d retailops \
        -v ON_ERROR_STOP=1 -P pager=off "$@"
}

# Refuser de produire une fausse mesure « avant ».
exists="$(psql_db -Atc \
    "SELECT to_regclass('retail.idx_orders_customer_recent') IS NOT NULL;")"

if [[ "$exists" == "t" ]]; then
    echo "ARRÊT : l'index existe déjà ; mesure avant impossible." >&2
    exit 1
fi

# Relever le contexte avant toute optimisation.
psql_db \
    -c "SELECT version(), current_database(), clock_timestamp();" \
    -c "SELECT count(*) AS commandes FROM retail.orders;" \
    -c "SELECT indexname, indexdef
        FROM pg_indexes
        WHERE schemaname = 'retail' AND tablename = 'orders';" \
    -c "SHOW shared_buffers;" \
    > evidence/perf_context.txt

# Actualiser les statistiques une seule fois avant la comparaison.
psql_db -c "ANALYZE retail.orders;"

measure() {
    local output="$1"

    # Échauffement non inclus dans les preuves chronométrées.
    psql_db -f /sql/projet/06_requete.sql > /dev/null

    {
    for i in 1 2 3 4 5; do
        printf '\n--- Mesure %s ---\n' "$i"
        psql_db -f /sql/projet/06_requete.sql
    done
    } > "$output"
}

measure evidence/perf_before.txt

psql_db -f /sql/projet/06_optimisation.sql \
    > evidence/perf_index.txt

measure evidence/perf_after.txt

echo "Terminé : preuves disponibles dans evidence/."