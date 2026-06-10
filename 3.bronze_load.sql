-- 1.INGESTING CUSTOMERS TABLE --
COPY INTO DB_bronze_customers 
(   customer_id, 
    first_name, 
    last_name, 
    email, 
    city, 
    country, 
    customer_segment, 
    last_updated, 
    source_file, 
    row_hash)
FROM (SELECT $1, $2, $3, $4, $5, $6, $7, $8, 
      METADATA$FILENAME, 
      NULL FROM @bronze_divya/incoming/)
FILE_FORMAT = (FORMAT_NAME = 'bronze_csv_file_format')
PATTERN = 'customers_source_.._.._.{4}\.csv';

-- HASHING CUSTOMERS TABLE --
UPDATE DB_bronze_customers 
SET row_hash = MD5(CONCAT_WS('|', 
                              customer_id, 
                              first_name, 
                              last_name, 
                              email, 
                              city, 
                              country, 
                              customer_segment, 
                              last_updated))
WHERE row_hash IS NULL;


-- 2.INGESTING PRODUCTS TABLE --
COPY INTO DB_bronze_products 
(   product_id, 
    product_name, 
    category, 
    price, 
    cost, 
    supplier_id, 
    last_updated, 
    source_file, 
    row_hash)
FROM (SELECT $1, $2, $3, $4, $5, $6, $7, 
      METADATA$FILENAME, 
      NULL FROM @bronze_divya/incoming/)
FILE_FORMAT = (FORMAT_NAME = 'bronze_csv_file_format')
PATTERN = 'products_source_.._.._....\.csv';


-- HASHING PRODUCTS TABLE --
UPDATE DB_bronze_products 
SET row_hash = MD5(CONCAT_WS('|', 
                              product_id, 
                              product_name, 
                              category, 
                              price, 
                              cost, 
                              supplier_id, 
                              last_updated))
WHERE row_hash IS NULL;


--3. INGESTING ORDERS TABLE --
COPY INTO DB_bronze_orders 
(   order_id, 
    customer_id, 
    order_date, 
    order_status, 
    total_amount, 
    payment_method, 
    created_at, 
    source_file, 
    row_hash)
FROM (SELECT $1, $2, $3, $4, $5, $6, $7, 
      METADATA$FILENAME, 
      NULL FROM @bronze_divya/incoming/)
FILE_FORMAT = (FORMAT_NAME = 'bronze_csv_file_format')
PATTERN = 'orders_source_.._.._.{4}\.csv';

-- HASHING ORDERS TABLE --
UPDATE DB_bronze_orders 
SET row_hash = MD5(CONCAT_WS('|', 
                              COALESCE(order_id,''), 
                              COALESCE(customer_id,''),
                              COALESCE(order_date,''), 
                              COALESCE(order_status,''), 
                              COALESCE(total_amount,''),
                              COALESCE(payment_method,''), 
                              COALESCE(created_at,'')))
WHERE row_hash IS NULL;



-- 4.INGESTING ORDER_ITEMS --
COPY INTO DB_bronze_order_items 
(   order_item_id, 
    order_id, 
    product_id, 
    quantity, 
    unit_price, 
    discount_percent, 
    source_file, 
    row_hash)
FROM (SELECT $1, $2, $3, $4, $5, $6, 
      METADATA$FILENAME, 
      NULL FROM @bronze_divya/incoming/)
FILE_FORMAT = (FORMAT_NAME = 'bronze_csv_file_format')
PATTERN = 'order_items_source.*\.csv';

-- HASHING ORDER_ITEMS TABLE --
UPDATE DB_bronze_order_items 
SET row_hash = MD5(CONCAT_WS('|', 
                            order_item_id, 
                            order_id, 
                            product_id, 
                            quantity, 
                            unit_price, 
                            discount_percent))
WHERE row_hash IS NULL;


select * from db_bronze_orders;