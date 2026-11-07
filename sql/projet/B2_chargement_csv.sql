\set ON_ERROR_STOP on
\copy retail.customers   FROM '/data/customers.csv'   WITH (FORMAT csv, HEADER true)
\copy retail.products    FROM '/data/products.csv'    WITH (FORMAT csv, HEADER true)
\copy retail.orders      FROM '/data/orders.csv'      WITH (FORMAT csv, HEADER true)
\copy retail.order_items FROM '/data/order_items.csv' WITH (FORMAT csv, HEADER true)