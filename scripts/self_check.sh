#!/usr/bin/env bash
# Auto-contrôle PASS/FAIL (équivalent maison de evaluation/verifier.sh : lecture seule, ne modifie rien)
. "$(dirname "$0")/lib.sh"
P=0; F=0
chk() { # chk "libellé" "commande qui doit réussir"
  if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; P=$((P+1)); else echo "FAIL  $1"; F=$((F+1)); fi
}
restored_orders() { psqla -d retail_restore_check -Atc "SELECT count(*) FROM retail.orders"; }
eqq() { [ "$(q "$1" 2>/dev/null)" = "$2" ]; }

chk "PostgreSQL 17"                         "q 'SHOW server_version_num' | grep -q '^17'"
chk "4 tables dans retail"                  "eqq \"SELECT count(*) FROM pg_tables WHERE schemaname='retail'\" 4"
chk "3 clés étrangères (ou plus)"           "[ \$(q \"SELECT count(*) FROM pg_constraint WHERE contype='f' AND connamespace='retail'::regnamespace\") -ge 3 ]"
chk "customers = 300"                       "eqq 'SELECT count(*) FROM retail.customers' 300"
chk "products = 80"                         "eqq 'SELECT count(*) FROM retail.products' 80"
chk "orders = 5000"                         "eqq 'SELECT count(*) FROM retail.orders' 5000"
chk "order_items ≈ 10000 (9000-11000)"      "[ \$(q 'SELECT count(*) FROM retail.order_items') -ge 9000 ] && [ \$(q 'SELECT count(*) FROM retail.order_items') -le 11000 ]"
chk "4 rôles attendus"                      "eqq \"SELECT count(*) FROM pg_roles WHERE rolname IN ('retail_ro','retail_rw','analyst_login','app_login')\" 4"
chk "retail_ro/rw NOLOGIN ; *_login LOGIN"  "eqq \"SELECT count(*) FROM pg_roles WHERE (rolname IN ('retail_ro','retail_rw') AND NOT rolcanlogin) OR (rolname IN ('analyst_login','app_login') AND rolcanlogin)\" 4"
chk "aucun rôle applicatif superuser"       "eqq \"SELECT count(*) FROM pg_roles WHERE rolname IN ('analyst_login','app_login') AND rolsuper\" 0"
chk "analyst_login : SELECT oui"            "eqq \"SELECT has_table_privilege('analyst_login','retail.orders','SELECT')\" t"
chk "analyst_login : écriture NON"          "eqq \"SELECT has_table_privilege('analyst_login','retail.orders','INSERT') OR has_table_privilege('analyst_login','retail.orders','UPDATE') OR has_table_privilege('analyst_login','retail.orders','DELETE')\" f"
chk "app_login : INSERT+UPDATE orders"      "eqq \"SELECT has_table_privilege('app_login','retail.orders','INSERT') AND has_table_privilege('app_login','retail.orders','UPDATE')\" t"
chk "SSL activé"                            "eqq 'SHOW ssl' on"
chk "SCRAM-SHA-256"                         "eqq 'SHOW password_encryption' scram-sha-256"
chk "pgaudit préchargé"                     "q 'SHOW shared_preload_libraries' | grep -q pgaudit"
chk "extension pgaudit installée"           "eqq \"SELECT count(*) FROM pg_extension WHERE extname='pgaudit'\" 1"
chk "pgaudit.log configuré (≠ none)"        "[ \"\$(q 'SHOW pgaudit.log')\" != 'none' ] && [ -n \"\$(q 'SHOW pgaudit.log')\" ]"
chk "archive_mode = on"                     "eqq 'SHOW archive_mode' on"
chk "WAL réellement archivés"               "[ \$(q 'SELECT archived_count FROM pg_stat_archiver') -ge 1 ]"
chk "index métier présent"                  "[ \$(q \"SELECT count(*) FROM pg_indexes WHERE schemaname='retail' AND indexname LIKE 'idx_%'\") -ge 1 ]"
chk "dump lisible (pg_restore -l)"          "[ -s backups/retail_admin.dump ] && $DC exec -T db pg_restore -l < backups/retail_admin.dump"
chk "base retail_restore_check distincte"   "eqq \"SELECT count(*) FROM pg_database WHERE datname='retail_restore_check'\" 1"
chk "5000 commandes retrouvées (base restaurée)" '[ "$(restored_orders)" = 5000 ]'
for f in evidence/perf_before.txt evidence/perf_after.txt docs/rgpd.md docs/supervision.md evidence/03_droits.txt evidence/06_restauration.txt evidence/04_audit_log_expurge.txt; do
  chk "présent : $f" "[ -s $f ]"
done
chk "aucun .env versionné"                  "! git ls-files --error-unmatch .env"
echo; echo "Bilan : $P PASS, $F FAIL"; [ "$F" -eq 0 ]
