-- ========================================================
-- SQL Migration Script: 001_create_tables.sql
-- This script sets up the database schema for the order 
-- reporting system. It creates the `customers`, `orders`, 
-- and `items` tables if they do not already exist.
-- ========================================================

-- ========================================================
-- Step 1: Create `customers` Table
-- ========================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL
);

-- ========================================================
-- Step 2: Create `orders` Table
-- ========================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    order_number TEXT NOT NULL,
    order_date TEXT NOT NULL,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- ========================================================
-- Step 3: Create `items` Table
-- ========================================================
CREATE TABLE IF NOT EXISTS items (
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    price REAL NOT NULL,
    order_id INTEGER,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);
