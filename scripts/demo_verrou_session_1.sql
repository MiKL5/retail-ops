\set ON_ERROR_STOP on
\echo '--- SESSION 1 : transaction ouverte ---'
BEGIN;
UPDATE retail.orders
SET status = 'paid'
WHERE order_id = 1;

\echo '--- SESSION 1 : transaction maintenue ouverte ---'
\echo 'Exécutez maintenant la session 2, puis revenez ici.'
\prompt 'Appuyez sur Entrée pour annuler la transaction : ' reponse
ROLLBACK;
\echo '--- SESSION 1 : transaction annulée ---'