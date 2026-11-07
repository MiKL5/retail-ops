#!/bin/bash
# Génère (une seule fois, dans le volume pgtls) une CA de laboratoire et un certificat serveur
# signé par cette CA, puis délègue à l'entrypoint officiel de PostgreSQL.
set -e
TLS=/etc/postgresql/tls

if [ "$(id -u)" = "0" ] && [ ! -f "$TLS/server.key" ]; then
  echo "[tls] Génération de la CA locale et du certificat serveur..."
  cd "$TLS"
  openssl genrsa -out ca.key 4096 2>/dev/null
  openssl req -x509 -new -nodes -key ca.key -sha256 -days 825 \
          -subj "/CN=RetailOps Lab CA" -out ca.crt
  openssl genrsa -out server.key 2048 2>/dev/null
  openssl req -new -key server.key -subj "/CN=localhost" -out server.csr
  printf "subjectAltName=DNS:localhost,DNS:db,IP:127.0.0.1\nextendedKeyUsage=serverAuth\n" > ext.cnf
  openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
          -out server.crt -days 825 -sha256 -extfile ext.cnf 2>/dev/null
  # En production, la clé de la CA reste hors ligne : on la supprime ici aussi.
  rm -f ca.key ca.srl server.csr ext.cnf
  chown postgres:postgres server.key server.crt ca.crt
  chmod 600 server.key
  chmod 644 server.crt ca.crt
fi

exec docker-entrypoint.sh "$@"
