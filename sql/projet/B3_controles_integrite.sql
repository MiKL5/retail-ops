SELECT           'customers' t, count(*) FROM retail.customers
UNION ALL SELECT 'products',    count(*) FROM retail.products
UNION ALL SELECT 'orders',      count(*) FROM retail.orders
UNION ALL SELECT 'order_items', count(*) FROM retail.order_items;

SELECT email, count(*)
FROM retail.customers
GROUP BY email HAVING count(*) > 1;

SELECT count(*) AS orphelins
FROM      retail.order_items oi
LEFT JOIN retail.orders o USING (order_id)
WHERE o.order_id IS NULL;

-- Commandes avec client inexistant
SELECT count(*) AS orphelins_orders
FROM      retail.orders o
LEFT JOIN retail.customers c USING (customer_id)
WHERE c.customer_id IS NULL;

-- Doublons de SKU
SELECT sku, count(*)
FROM retail.products
GROUP BY sku HAVING count(*) > 1;

-- Lignes de commande avec produit inexistant
SELECT count(*) AS orphelins_items
FROM      retail.order_items oi
LEFT JOIN retail.products p USING (product_id)
WHERE p.product_id IS NULL;