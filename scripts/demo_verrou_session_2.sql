\set ON_ERROR_STOP on
\echo '--- SESSION 2 : tentative de modification ---'
BEGIN;
UPDATE retail.orders
SET status = 'paid'
WHERE order_id = 1;
ROLLBACK;
\echo '--- SESSION 2 : terminée ---'