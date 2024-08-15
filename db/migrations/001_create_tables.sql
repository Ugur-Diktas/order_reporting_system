-- ========================================================
-- SQL Migration Script: 001_create_tables.sql
-- This script sets up the database schema for the order 
-- reporting system according to the revised structure.
-- ========================================================

-- ========================================================
-- Step 1: Create `orders` Table
-- ========================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    order_number TEXT NOT NULL,
    order_date TEXT NOT NULL,
    customer_id INTEGER,
    item_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE
);

-- ========================================================
-- Step 2: Create `customers` Table
-- ========================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES orders(customer_id) ON DELETE CASCADE
);

-- ========================================================
-- Step 3: Create `items` Table
-- ========================================================
CREATE TABLE IF NOT EXISTS items (
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    price REAL NOT NULL,
    FOREIGN KEY (item_id) REFERENCES orders(item_id) ON DELETE CASCADE
);
