-- DROP TABLE IF EXISTS items;
-- DROP TABLE IF EXISTS orders;
-- DROP TABLE IF EXISTS customers;

CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    order_number TEXT NOT NULL,
    order_date TEXT NOT NULL,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS items (
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    price REAL NOT NULL,
    order_id INTEGER,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
