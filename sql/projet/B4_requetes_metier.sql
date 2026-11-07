-- 1. Chiffre d''affaires par catégorie (commandes payées)
SELECT p.category,
       count(DISTINCT o.order_id) AS commandes,
       sum(oi.quantity * oi.unit_price)::numeric(12,2) AS ca
FROM retail.order_items oi
JOIN retail.orders   o USING (order_id)
JOIN retail.products p USING (product_id)
WHERE o.status = 'paid'
GROUP BY p.category
ORDER BY ca DESC;

-- 2. Dix meilleurs clients (sans données d'identité)
SELECT c.customer_id, c.region,
       count(DISTINCT o.order_id) AS commandes,
       sum(oi.quantity * oi.unit_price)::numeric(12,2) AS ca
FROM retail.customers c
JOIN retail.orders      o  ON o.customer_id = c.customer_id
JOIN retail.order_items oi ON oi.order_id   = o.order_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.region
ORDER BY ca DESC
LIMIT 10;

-- 3. Évolution mensuelle par canal
SELECT date_trunc('month', o.ordered_at)::date AS mois,
       o.channel,
       count(DISTINCT o.order_id) AS commandes,
       sum(oi.quantity * oi.unit_price)::numeric(12,2) AS ca
FROM retail.orders o
JOIN retail.order_items oi USING (order_id)
WHERE o.status = 'paid'
GROUP BY mois, o.channel
ORDER BY mois, o.channel;