set -euo pipefail
docker compose exec -T db psql -U postgres -d retailops <<'SQL'
CREATE TABLE IF NOT EXISTS retail.audit_demo(i int);
DROP TABLE retail.audit_demo;
UPDATE retail.orders SET status = status WHERE order_id = 1;
SELECT count(*) FROM retail.customers;
SQL

docker compose logs db --since 5m | grep 'AUDIT:' > evidence/audit.raw.log   # ignoré par Git

# Expurgation avant versionnement
sed -E \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<EMAIL>/g' \
    -e 's/[0-9]{1,3}(\.[0-9]{1,3}){3}/<IP>/g' \
    -e 's/(password|PASSWORD)[^,;)]*/\1 <REDACTED>/g' \
    evidence/audit.raw.log > evidence/audit_expurge.log
wc -l evidence/audit_expurge.log