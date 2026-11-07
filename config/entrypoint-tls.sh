#!/usr/bin/env bash
set -euo pipefail
install -d -m 700 -o postgres -g postgres /var/lib/postgresql/tls
install -m    644 -o postgres -g postgres /certs/server.crt /var/lib/postgresql/tls/server.crt
install -m    600 -o postgres -g postgres /certs/server.key /var/lib/postgresql/tls/server.key
install -d -m 700 -o postgres -g postgres /wal_archive
exec docker-entrypoint.sh "$@"