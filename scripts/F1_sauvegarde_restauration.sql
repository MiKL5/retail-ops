# Dump logique au format custom
pg_dump -U postgres -Fc -d retailops -f backups/retail_admin.dump

# Restauration sur une base distincte
createdb -U postgres retail_restore_check
pg_restore -U postgres -d retail_restore_check backups/retail_admin.dump


-- dans psql, comparaison 
-- SELECT 'source' AS base, count(*) FROM retail.orders
-- UNION ALL
-- SELECT 'restauree', count(*) FROM retail_restore_check.retail.orders;