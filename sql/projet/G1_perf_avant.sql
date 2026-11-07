EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    ordered_at,
    status,
    channel
FROM retail.orders
WHERE customer_id = 154
ORDER BY ordered_at DESC, order_id DESC
LIMIT 20;