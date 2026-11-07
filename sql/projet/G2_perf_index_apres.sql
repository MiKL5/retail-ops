\set ON_ERROR_STOP on

CREATE INDEX idx_orders_customer_recent
ON retail.orders (
    customer_id,
    ordered_at DESC,
    order_id DESC
);

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'retail'
    AND indexname = 'idx_orders_customer_recent';

SELECT
    pg_size_pretty(
        pg_relation_size('retail.idx_orders_customer_recent')
    ) AS taille_index;

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, ordered_at, status, channel
FROM   retail.orders
WHERE  customer_id = 154
ORDER BY ordered_at DESC, order_id DESC
LIMIT 20;