-- DROP TABLE DB_silver_customers;
-- DROP TABLE DB_silver_products;
-- DROP TABLE DB_silver_orders;
-- DROP TABLE DB_dim_order_status;
-- DROP TABLE DB_silver_order_items;

-- 1. Silver Customers (SCD Type 2)
CREATE TABLE IF NOT EXISTS DB_silver_customers (
    customer_key NUMBER AUTOINCREMENT,    -- surrogate key
    customer_id INT NOT NULL,         
    first_name STRING,
    last_name STRING,
    email STRING,
    city STRING,
    country STRING,
    customer_segment STRING,
 
    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL,
    row_hash STRING NOT NULL,
 
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP
);


-- 2. Silver Products (SCD Type 2)
CREATE OR REPLACE TABLE DB_silver_products (
    product_key NUMBER AUTOINCREMENT,   -- surrogate key
    product_id INT NOT NULL,            -- business key
    product_name STRING,
    category STRING,
    price FLOAT,
    cost FLOAT,
    supplier_id INT,

    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL,

    row_hash STRING NOT NULL,

    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP

);


-- 3. Silver Orders --
CREATE TABLE IF NOT EXISTS DB_silver_orders (
    order_key INT IDENTITY(1,1),    -- Surrogate key
    order_id INT NOT NULL,          -- Business key
    customer_key INT,
    customer_id INT,
    order_date DATE,
    order_status_key INT,
    total_amount NUMBER(10,2),
    payment_method STRING,
    created_at TIMESTAMP,
 
    effective_from_date DATE NOT NULL,
    effective_to_date DATE NOT NULL,
    is_current BOOLEAN NOT NULL,
 
    processed_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS DB_dim_order_status (
    order_status_key INT IDENTITY(1,1),     -- surrogate key
    order_status_code STRING NOT NULL,
    order_status_desc STRING,
    is_active BOOLEAN DEFAULT TRUE,
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
INSERT INTO DB_dim_order_status (order_status_code, order_status_desc)
SELECT *
FROM VALUES
('NEW', 'New order'),
('PROCESSING', 'Order is being processed'),
('SHIPPED', 'Order shipped'),
('DELIVERED', 'Order delivered'),
('CANCELLED', 'Order cancelled'),
('UNKNOWN', 'Unknown or invalid status')
AS src(order_status_code, order_status_desc)
WHERE NOT EXISTS (
    SELECT 1
    FROM DB_dim_order_status tgt
    WHERE tgt.order_status_code = src.order_status_code
);




-- 4. Silver Order Items (Type 1 - Fact)
CREATE TABLE IF NOT EXISTS DB_silver_order_items (
    order_item_id INT,        
    order_key INT,            
    product_key INT,          
    order_id INT,             
    product_id INT,         
    quantity INT,
    unit_price NUMBER(10,2),
    discount_percent NUMBER(5,2),
    line_total NUMBER(12,2), 
    effective_from_date DATE NOT NULL,
    effective_to_date DATE,
    is_current BOOLEAN NOT NULL,
    processed_timestamp TIMESTAMP
);