\set ON_ERROR_STOP on
CREATE TABLE retail.audit_demo(i int);
DROP TABLE retail.audit_demo;
UPDATE retail.orders SET status = status WHERE order_id = 1;
SELECT count(*) FROM retail.customers;