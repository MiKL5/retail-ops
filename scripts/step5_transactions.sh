#!/usr/bin/env bash
# Étape 5 — Transactions, blocage entre deux sessions, stockage
. "$(dirname "$0")/lib.sh"
psqla -d retailops -f /sql/07_transactions.sql 2>&1 | tee evidence/05_transactions.txt

{
  echo "### $(date -u +%FT%TZ) — Blocage provoqué"
  echo "Session A : ouvre une transaction, verrouille la ligne order_id=1 et la garde 40 s"
  psqla -d retailops -c "SET application_name='session_A'; BEGIN; UPDATE retail.orders SET status=status WHERE order_id=1; SELECT pg_sleep(40); COMMIT;" >/dev/null 2>&1 &
  PID_A=$!
  sleep 2
  echo "Session B : tente de modifier la MÊME ligne -> elle attend"
  psqla -d retailops -c "SET application_name='session_B'; UPDATE retail.orders SET status=status WHERE order_id=1;" >/dev/null 2>&1 &
  PID_B=$!
  sleep 3
  echo; echo ">>> Diagnostic (session C = administrateur)"
  psqla -d retailops -f /sql/12_lock_observer.sql
  echo; echo ">>> Résolution : on termine la session BLOQUANTE (A) -> son travail est annulé, B passe"
  psqla -d retailops -Atc "SELECT pg_terminate_backend(p) FROM (SELECT DISTINCT unnest(pg_blocking_pids(pid)) AS p FROM pg_stat_activity WHERE application_name='session_B') s;"
  wait $PID_A 2>/dev/null || true
  wait $PID_B 2>/dev/null || true
  echo; echo ">>> Après résolution : plus aucune session bloquée"
  psqla -d retailops -f /sql/12_lock_observer.sql
} 2>&1 | tee evidence/05_blocage.txt

psqla -d retailops -f /sql/08_storage.sql 2>&1 | tee evidence/05_stockage.txt
