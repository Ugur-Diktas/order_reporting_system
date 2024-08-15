-- ========================================================
-- SQL Migration Script: 001_create_tables.sql
-- This script sets up the database schema for the order 
-- reporting system.
-- ========================================================

-- ========================================================
-- Create `orders` Table
-- This table stores all orders and references both customers 
-- and items via foreign keys.
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
-- Create `customers` Table
-- This table stores customer information. The customer_id 
-- is referenced by the orders table.
-- ========================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL
);

-- ========================================================
-- Create `items` Table
-- This table stores item details. The item_id is referenced 
-- by the orders table.
-- ========================================================
CREATE TABLE IF NOT EXISTS items (
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    price REAL NOT NULL
);
