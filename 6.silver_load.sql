-- Silver Customers --
CREATE OR REPLACE TEMP TABLE temp_latest_src AS
SELECT
    lb.customer_id,
    lb.first_name,
    lb.last_name,
    lb.email,
    lb.city,
    lb.country,
    lb.customer_segment,
    lb.row_hash,
    TO_DATE(TRY_TO_TIMESTAMP(lb.last_updated, 'DD-MM-YYYY HH24:MI')) AS last_updated_date,
    sc.row_hash AS silver_row_hash

FROM (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        city,
        country,
        customer_segment,
        last_updated,
        ingestion_timestamp,
        row_hash,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY ingestion_timestamp DESC
        ) AS rn
    FROM DB_bronze_customers
) lb

LEFT JOIN DB_silver_customers sc
    ON lb.customer_id = sc.customer_id
    AND sc.is_current = TRUE

WHERE lb.rn = 1;

MERGE INTO DB_silver_customers sc
USING temp_latest_src src
ON sc.customer_id = src.customer_id
AND sc.is_current = TRUE

WHEN MATCHED
    AND src.row_hash <> sc.row_hash

THEN UPDATE SET
    sc.effective_to_date = src.last_updated_date - 1,
    sc.is_current = FALSE,
    sc.updated_timestamp = CURRENT_TIMESTAMP;

INSERT INTO DB_silver_customers (
    customer_id,
    first_name,
    last_name,
    email,
    city,
    country,
    customer_segment,
    effective_from_date,
    effective_to_date,
    is_current,
    row_hash
)

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    country,
    customer_segment,
    last_updated_date,
    DATE '9999-12-31',
    TRUE,
    row_hash

FROM temp_latest_src
WHERE silver_row_hash IS NULL
   OR row_hash <> silver_row_hash;




-- Silver Products --
CREATE OR REPLACE TEMP TABLE temp_latest_products AS
SELECT
    lb.product_id,
    lb.product_name,
    lb.category,
    lb.price,
    lb.cost,
    lb.supplier_id,
    lb.row_hash,
    COALESCE(TRY_TO_DATE(lb.last_updated), CURRENT_DATE) AS last_updated_date,
    sp.row_hash AS silver_row_hash

FROM (
    SELECT
        product_id,
        product_name,
        category,
        price,
        cost,
        supplier_id,
        last_updated,
        ingestion_timestamp,
        row_hash,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY ingestion_timestamp DESC
        ) AS rn
    FROM DB_bronze_products
) lb

LEFT JOIN DB_silver_products sp
    ON lb.product_id = sp.product_id
    AND sp.is_current = TRUE

WHERE lb.rn = 1;

MERGE INTO DB_silver_products sp
USING temp_latest_products src
ON sp.product_id = src.product_id
AND sp.is_current = TRUE

WHEN MATCHED
    AND src.row_hash <> sp.row_hash

THEN UPDATE SET
    sp.effective_to_date = src.last_updated_date - 1,
    sp.is_current = FALSE,
    sp.updated_timestamp = CURRENT_TIMESTAMP;

INSERT INTO DB_silver_products (
    product_id,
    product_name,
    category,
    price,
    cost,
    supplier_id,
    effective_from_date,
    effective_to_date,
    is_current,
    row_hash
)

SELECT
    product_id,
    product_name,
    category,
    price,
    cost,
    supplier_id,
    last_updated_date,
    DATE '9999-12-31',
    TRUE,
    row_hash

FROM temp_latest_products
WHERE silver_row_hash IS NULL
   OR row_hash <> silver_row_hash;

select * from DB_silver_products;



-- Silver orders --
CREATE OR REPLACE TEMP TABLE temp_latest_orders AS
WITH latest_bronze AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY ingestion_timestamp DESC
           ) AS rn
    FROM DB_bronze_orders
)

SELECT
    bo.order_id,
    sc.customer_key,
    bo.customer_id,
    TRY_TO_DATE(bo.order_date, 'DD-MM-YYYY') AS order_date,
    dos.order_status_key,

    CASE WHEN bo.total_amount >= 0 THEN bo.total_amount END AS total_amount,
    COALESCE(bo.payment_method, 'UNKNOWN') AS payment_method,
    CURRENT_TIMESTAMP AS created_at,

    COALESCE(
        TRY_TO_DATE(bo.order_date, 'DD-MM-YYYY'),
        CURRENT_DATE
    ) AS effective_from_date,

    so.order_status_key AS silver_status_key

FROM latest_bronze bo

LEFT JOIN DB_silver_customers sc
    ON bo.customer_id = sc.customer_id
   AND TO_DATE(bo.ingestion_timestamp)
       BETWEEN sc.effective_from_date AND sc.effective_to_date

LEFT JOIN DB_dim_order_status dos
    ON COALESCE(bo.order_status, 'UNKNOWN') = dos.order_status_code

LEFT JOIN DB_silver_orders so
    ON bo.order_id = so.order_id
   AND so.is_current = TRUE

WHERE bo.rn = 1;

MERGE INTO DB_silver_orders so
USING temp_latest_orders src
ON so.order_id = src.order_id
AND so.is_current = TRUE

WHEN MATCHED
AND so.order_status_key <> src.order_status_key

THEN UPDATE SET
    effective_to_date = src.effective_from_date - 1,
    is_current = FALSE,
    processed_timestamp = CURRENT_TIMESTAMP;

INSERT INTO DB_silver_orders (
    order_id,
    customer_key,
    customer_id,
    order_date,
    order_status_key,
    total_amount,
    payment_method,
    created_at,
    effective_from_date,
    effective_to_date,
    is_current,
    processed_timestamp
)

SELECT
    order_id,
    customer_key,
    customer_id,
    order_date,
    order_status_key,
    total_amount,
    payment_method,
    created_at,
    effective_from_date,
    DATE '9999-12-31',
    TRUE,
    CURRENT_TIMESTAMP

FROM temp_latest_orders
WHERE silver_status_key IS NULL
   OR order_status_key <> silver_status_key;

select * from DB_silver_orders;




-- silver order_items --
INSERT INTO DB_silver_order_items (
    order_item_id,
    order_key,
    product_key,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_percent,
    line_total,
    effective_from_date,
    effective_to_date,
    is_current,
    processed_timestamp
)
SELECT
    b.order_item_id,
    so.order_key,
    sp.product_key,
    b.order_id,
    b.product_id,
    b.quantity,
    b.unit_price,
    b.discount_percent,
    (COALESCE(b.quantity, 0) * COALESCE(b.unit_price,0))* (1 - (COALESCE(b.discount_percent, 0) / 100)) AS line_total,
    so.order_date AS effective_from_date,
    DATE '9999-12-31' AS effective_to_date,
    TRUE AS is_current,
    CURRENT_TIMESTAMP
FROM (
    SELECT 
        oi.*, 
        ROW_NUMBER() OVER (
            PARTITION BY order_item_id 
            ORDER BY ingestion_timestamp DESC
        ) AS rn
    FROM DB_bronze_order_items oi
) b

LEFT JOIN DB_silver_orders so 
    ON b.order_id = so.order_id
   AND so.is_current = TRUE

LEFT JOIN DB_silver_products sp 
    ON b.product_id = sp.product_id
   AND so.order_date BETWEEN sp.effective_from_date AND sp.effective_to_date

WHERE b.rn = 1
AND NOT EXISTS (
    SELECT 1 
    FROM DB_silver_order_items s 
    WHERE s.order_item_id = b.order_item_id
);

select * from DB_silver_order_items;
