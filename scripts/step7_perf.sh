#!/usr/bin/env bash
# Étape 7 — Plans avant/après index, coût en écriture, supervision
. "$(dirname "$0")/lib.sh"
{ echo "### AVANT optimisation — $(date -u +%FT%TZ)"; psqla -d retailops -f /sql/09_perf_drop_indexes.sql >/dev/null; psqla -d retailops -f /sql/09_perf_query.sql; } 2>&1 | tee evidence/perf_before.txt
{ echo "### APRÈS optimisation — $(date -u +%FT%TZ)"; psqla -d retailops -f /sql/09_perf_create_indexes.sql >/dev/null; psqla -d retailops -f /sql/09_perf_query.sql; } 2>&1 | tee evidence/perf_after.txt
{ echo "### Coût en écriture des index — $(date -u +%FT%TZ)"; psqla -d retailops -f /sql/09_perf_write_cost.sql; } 2>&1 | tee evidence/perf_write_cost.txt
psqla -d retailops -f /sql/10_supervision.sql 2>&1 | tee evidence/07_supervision.txt
