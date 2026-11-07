#!/usr/bin/env bash
# Preuve de persistance : le contenu survit à la suppression du CONTENEUR (pas du volume)
. "$(dirname "$0")/lib.sh"
{
  echo "### $(date -u +%FT%TZ) — Persistance"
  echo "Avant : orders = $(q 'SELECT count(*) FROM retail.orders')"
  $DC restart db;           $DC up -d --wait
  echo "Après restart          : orders = $(q 'SELECT count(*) FROM retail.orders')"
  $DC down;                 $DC up -d --wait      # supprime le conteneur, PAS le volume
  echo "Après down + up        : orders = $(q 'SELECT count(*) FROM retail.orders')"
  echo "(NE PAS lancer 'docker compose down -v' : cela supprime aussi le volume et toutes les données.)"
} 2>&1 | tee evidence/02_persistance.txt
