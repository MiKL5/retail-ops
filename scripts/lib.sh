#!/usr/bin/env bash
# Fonctions communes. À sourcer : . scripts/lib.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[ -f .env ] || { echo "ERREUR : .env absent. Faites : cp .env.example .env  puis changez les mots de passe." >&2; exit 1; }
set -a; . ./.env; set +a
DC="docker compose"
mkdir -p evidence backups

# psql en superutilisateur (socket Unix dans le conteneur, mot de passe via variable d'environnement)
psqla() { $DC exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" db psql -X -v ON_ERROR_STOP=1 -U postgres "$@"; }
# requête scalaire rapide sur retailops
q() { psqla -d retailops -Atc "$1"; }
# psql en tant qu'utilisateur applicatif, en TLS avec vérification complète du certificat (verify-full)
psql_as() {
  local u="$1" p="$2"; shift 2
  $DC exec -T -e PGPASSWORD="$p" -e PGSSLMODE=verify-full -e PGSSLROOTCERT=/etc/postgresql/tls/ca.crt \
       db psql -X -h localhost -U "$u" -d retailops "$@"
}
# masque secrets et emails dans un flux de logs
redact() {
  sed -E "s/(PASSWORD +)'[^']*'/\1'<REDACTED>'/Ig; s/[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}/<email>/g"
}
