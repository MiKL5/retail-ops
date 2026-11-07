\set ON_ERROR_STOP on
\echo '--- État initial ---'
SELECT order_id, status
FROM retail.orders
WHERE order_id = 1;

\echo '--- COMMIT : le changement devient durable ---'
BEGIN;
UPDATE retail.orders
SET status = 'pending'
WHERE order_id = 1;
SELECT order_id, status   -- visible dans la transaction
FROM retail.orders
WHERE order_id = 1;
COMMIT;
SELECT order_id, status   -- toujours 'pending'
FROM retail.orders
WHERE order_id = 1;

\echo '--- ROLLBACK : le changement est annulé ---'
BEGIN;
UPDATE retail.orders
SET status = 'cancelled'
WHERE order_id = 1;
SELECT order_id, status   -- 'cancelled' dans la transaction
FROM retail.orders
WHERE order_id = 1;
ROLLBACK;
SELECT order_id, status   -- retour à 'pending'
FROM retail.orders
WHERE order_id = 1;

\echo '--- Réinitialisation ---'
UPDATE retail.orders
SET status = 'paid'
WHERE order_id = 1;
SELECT order_id, status
FROM retail.orders
WHERE order_id = 1;