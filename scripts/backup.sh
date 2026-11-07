set -euo pipefail
mkdir -p backups evidence
docker compose exec -T db pg_dump -U postgres -d retailops \
    --format=custom --compress=6 --file=/backups/retail_admin.dump

docker compose exec -T db pg_restore --list /backups/retail_admin.dump | head -30 \
    > evidence/dump_table_des_matieres.txt
sha256sum backups/retail_admin.dump > evidence/dump.sha256