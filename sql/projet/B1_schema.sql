CREATE SCHEMA IF NOT EXISTS retail;

CREATE TABLE retail.customers (
    customer_id integer PRIMARY KEY,
    full_name   text NOT NULL,
    email       text NOT NULL UNIQUE,
    region      text NOT NULL,
    created_at  date NOT NULL
);

CREATE TABLE retail.products (
    product_id  integer PRIMARY KEY,
    sku         text NOT NULL UNIQUE,
    label       text NOT NULL,
    category    text NOT NULL,
    list_price  numeric(10,2) NOT NULL CHECK (list_price >= 0),
    active      boolean NOT NULL
);

CREATE TABLE retail.orders (
    order_id    integer PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES retail.customers(customer_id),
    ordered_at  timestamp NOT NULL,
    status      text NOT NULL CHECK (status IN ('paid','pending','cancelled','refunded')),
    channel     text NOT NULL CHECK (channel IN ('web','store','mobile'))
);

CREATE TABLE retail.order_items (
    item_id    integer PRIMARY KEY,
    order_id   integer NOT NULL REFERENCES retail.orders(order_id),
    product_id integer NOT NULL REFERENCES retail.products(product_id),
    quantity   integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0)
);