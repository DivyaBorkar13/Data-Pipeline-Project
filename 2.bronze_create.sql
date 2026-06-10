-- DROP TABLE DB_bronze_customers;
-- DROP TABLE DB_bronze_products;
-- DROP TABLE DB_bronze_orders;
-- DROP TABLE DB_bronze_order_items;

-- 1. Bronze Customers
CREATE TABLE IF NOT EXISTS DB_bronze_customers (
    customer_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    city VARCHAR,
    country VARCHAR,
    customer_segment VARCHAR,
    last_updated VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR,
    row_hash VARCHAR
);

-- 2. Bronze Products
CREATE TABLE IF NOT EXISTS DB_bronze_products (
    product_id INT,
    product_name VARCHAR,
    category VARCHAR,
    price FLOAT,
    cost FLOAT,
    supplier_id INT,
    last_updated VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR,
    row_hash VARCHAR
);

-- 3.Bronze Orders 
CREATE TABLE IF NOT EXISTS DB_bronze_orders (
    order_id INT,
    customer_id INT,
    order_date VARCHAR,
    order_status VARCHAR,
    total_amount FLOAT,
    payment_method VARCHAR,
    created_at VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR,
    row_hash VARCHAR
);

-- 4. Bronze Order Items
CREATE TABLE IF NOT EXISTS DB_bronze_order_items (
    order_item_id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price FLOAT,
    discount_percent INT,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_file VARCHAR,
    row_hash VARCHAR
);



-- SELECT * from DB_bronze_orders;
-- SELECT * from DB_bronze_customers;
-- SELECT * from DB_bronze_products;
-- SELECT * from DB_bronze_order_items;