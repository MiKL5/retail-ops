#!/usr/bin/env bash
set -euo pipefail
mkdir -p certs && cd certs
openssl req -x509 -newkey rsa:4096 -nodes -days 365 -keyout ca.key -out ca.crt -subj "/CN=RetailOps-Dev-CA"
openssl req -newkey rsa:4096 -nodes -keyout server.key -out server.csr -subj "/CN=localhost"
printf "subjectAltName=DNS:localhost,IP:127.0.0.1" > san.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -out server.crt -extfile san.ext