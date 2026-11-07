#!/usr/bin/env bash
# Étape 3 — Rôles, tests de droits (autorisé / refusé), TLS
. "$(dirname "$0")/lib.sh"
psqla -d retailops -v analyst_pw="$ANALYST_PASSWORD" -v app_pw="$APP_PASSWORD" -f /sql/05_roles.sql 2>&1 | tee evidence/03_roles.txt

{
  echo "### $(date -u +%FT%TZ) — Tests de droits (connexion TLS verify-full)"
  echo; echo "[analyst] SELECT sur orders            -> AUTORISÉ attendu"
  psql_as analyst_login "$ANALYST_PASSWORD" -Atc "SELECT count(*) FROM retail.orders;" 2>&1 || true
  echo; echo "[analyst] UPDATE sur orders            -> REFUSÉ attendu"
  psql_as analyst_login "$ANALYST_PASSWORD" -c "UPDATE retail.orders SET status='cancelled' WHERE order_id=1;" 2>&1 || true
  echo; echo "[analyst] DELETE sur customers         -> REFUSÉ attendu"
  psql_as analyst_login "$ANALYST_PASSWORD" -c "DELETE FROM retail.customers WHERE customer_id=1;" 2>&1 || true
  echo; echo "[analyst] CREATE TABLE                 -> REFUSÉ attendu"
  psql_as analyst_login "$ANALYST_PASSWORD" -c "CREATE TABLE retail.hack(id int);" 2>&1 || true
  echo; echo "[app] UPDATE orders (transaction annulée) -> AUTORISÉ attendu"
  psql_as app_login "$APP_PASSWORD" -c "BEGIN; UPDATE retail.orders SET status='paid' WHERE order_id=1 RETURNING order_id, status; ROLLBACK;" 2>&1 || true
  echo; echo "[app] DELETE sur orders                -> REFUSÉ attendu"
  psql_as app_login "$APP_PASSWORD" -c "DELETE FROM retail.orders WHERE order_id=1;" 2>&1 || true
  echo; echo "[app] UPDATE sur customers             -> REFUSÉ attendu"
  psql_as app_login "$APP_PASSWORD" -c "UPDATE retail.customers SET region='X' WHERE customer_id=1;" 2>&1 || true
  echo; echo "[app] CREATE ROLE                      -> REFUSÉ attendu"
  psql_as app_login "$APP_PASSWORD" -c "CREATE ROLE pirate SUPERUSER;" 2>&1 || true
} 2>&1 | tee evidence/03_droits.txt

{
  echo "### $(date -u +%FT%TZ) — Tests TLS"
  echo; echo "1) Connexion chiffrée + vérification de l'identité du serveur (verify-full, CA locale)"
  psql_as analyst_login "$ANALYST_PASSWORD" -c "SELECT ssl, version AS tls_version, cipher, bits FROM pg_stat_ssl WHERE pid = pg_backend_pid();" 2>&1 || true
  echo; echo "2) Sans TLS (sslmode=disable) -> REFUSÉ attendu (pg_hba : hostssl uniquement)"
  $DC exec -T -e PGPASSWORD="$ANALYST_PASSWORD" db psql -X "host=localhost dbname=retailops user=analyst_login sslmode=disable" -c "SELECT 1;" 2>&1 || true
  echo; echo "3) verify-full avec une MAUVAISE CA -> REFUSÉ attendu (le client ne fait pas confiance au serveur)"
  $DC exec -T -e PGPASSWORD="$ANALYST_PASSWORD" db psql -X "host=localhost dbname=retailops user=analyst_login sslmode=verify-full sslrootcert=/etc/ssl/certs/ca-certificates.crt" -c "SELECT 1;" 2>&1 || true
  echo; echo "4) Certificat serveur (sujet, SAN, émetteur, validité)"
  $DC exec -T db openssl x509 -in /etc/postgresql/tls/server.crt -noout -subject -issuer -dates -ext subjectAltName 2>&1 || true
  echo; echo "5) Mauvais mot de passe -> REFUSÉ attendu (SCRAM)"
  $DC exec -T -e PGPASSWORD="mauvais" -e PGSSLMODE=verify-full -e PGSSLROOTCERT=/etc/postgresql/tls/ca.crt db psql -X -h localhost -U analyst_login -d retailops -c "SELECT 1;" 2>&1 || true
} 2>&1 | tee evidence/03_tls.txt

# Récupère la CA publique pour tester depuis l'hôte (optionnel, nécessite psql sur l'hôte)
mkdir -p certs; $DC cp db:/etc/postgresql/tls/ca.crt certs/ca.crt >/dev/null && echo "CA publique copiée dans certs/ca.crt"
