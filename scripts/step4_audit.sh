#!/usr/bin/env bash
# Étape 4 — pgAudit : configuration + génération d'événements + extrait de log EXPURGÉ
. "$(dirname "$0")/lib.sh"
psqla -d retailops -f /sql/06_audit.sql 2>&1 | tee evidence/04_audit_config.txt

# Événements de test
START="$(date -u +%FT%TZ)"
psqla -d retailops -c "CREATE TABLE public.audit_probe(id int); DROP TABLE public.audit_probe;" >/dev/null
psql_as app_login "$APP_PASSWORD" -c "BEGIN; UPDATE retail.orders SET status='paid' WHERE order_id=1; ROLLBACK;" >/dev/null
psql_as analyst_login "$ANALYST_PASSWORD" -Atc "SELECT count(*) FROM retail.customers;" >/dev/null
sleep 1
{
  echo "### Extrait pgAudit depuis $START — emails et mots de passe masqués"
  $DC logs --no-log-prefix --since "$START" db 2>&1 | grep 'AUDIT:' | redact
} | tee evidence/04_audit_log_expurge.txt
echo
echo "Contrôle anti-fuite (doit afficher 0) : lignes contenant un mot de passe du .env dans le journal complet"
$DC logs --no-log-prefix db 2>&1 | grep -c -F -e "$ANALYST_PASSWORD" -e "$APP_PASSWORD" -e "$POSTGRES_PASSWORD" || true
