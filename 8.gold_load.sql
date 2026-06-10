-- gold_daily_sales_summary --
MERGE INTO DB_gold_daily_sales_summary g
USING (

    SELECT 
        o.order_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        SUM(oi.quantity) AS total_units_sold,
        AVG(o.total_amount) AS avg_order_value,

        COUNT(DISTINCT CASE 
            WHEN dos.order_status_code = 'CANCELLED' 
            THEN o.order_id 
        END) AS cancelled_orders,

        ROUND(
            COUNT(DISTINCT CASE 
                WHEN dos.order_status_code = 'CANCELLED' 
                THEN o.order_id 
            END) * 100.0
            / NULLIF(COUNT(DISTINCT o.order_id), 0),
            2
        ) AS cancellation_rate

    FROM DB_silver_orders o

    LEFT JOIN DB_silver_order_items oi
        ON o.order_id = oi.order_id

    LEFT JOIN DB_dim_order_status dos
        ON o.order_status_key = dos.order_status_key

    WHERE o.is_current = TRUE
      AND o.order_date >= (                                          -- Incremental logic
            SELECT COALESCE(MAX(order_date), '1900-01-01')
            FROM DB_gold_daily_sales_summary
      )
     GROUP BY o.order_date
) s

ON g.order_date = s.order_date

WHEN MATCHED THEN UPDATE SET
    g.total_orders = s.total_orders,
    g.total_revenue = s.total_revenue,
    g.total_units_sold = s.total_units_sold,
    g.avg_order_value = s.avg_order_value,
    g.cancelled_orders = s.cancelled_orders,
    g.cancellation_rate = s.cancellation_rate

WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_date,
    s.total_orders,
    s.total_revenue,
    s.total_units_sold,
    s.avg_order_value,
    s.cancelled_orders,
    s.cancellation_rate
);

SELECT * 
FROM DB_gold_daily_sales_summary
ORDER BY order_date DESC;



-- gold_customer_lifetime_value --
MERGE INTO DB_gold_customer_lifetime_value g
USING (

    WITH changed_customers AS (
        SELECT DISTINCT customer_id
        FROM DB_silver_orders
        WHERE order_date >= (
            SELECT COALESCE(MAX(last_order_date), '1900-01-01')
            FROM DB_gold_customer_lifetime_value
        )
    )

    SELECT
        o.customer_id,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        0 AS total_profit,
        AVG(o.total_amount) AS avg_order_value,
        sc.customer_segment,

        CASE 
            WHEN MAX(o.order_date) >= CURRENT_DATE - 90
            THEN TRUE ELSE FALSE
        END AS is_active

    FROM DB_silver_orders o

    JOIN changed_customers cc
        ON o.customer_id = cc.customer_id

    LEFT JOIN DB_silver_customers sc
        ON o.customer_id = sc.customer_id
       AND sc.is_current = TRUE

    WHERE o.is_current = TRUE

    GROUP BY o.customer_id, sc.customer_segment

) s
ON g.customer_id = s.customer_id

WHEN MATCHED THEN UPDATE SET
    g.first_order_date = s.first_order_date,
    g.last_order_date = s.last_order_date,
    g.total_orders = s.total_orders,
    g.total_revenue = s.total_revenue,
    g.total_profit = s.total_profit,
    g.avg_order_value = s.avg_order_value,
    g.customer_segment = s.customer_segment,
    g.is_active = s.is_active

WHEN NOT MATCHED THEN INSERT VALUES (
    s.customer_id,
    s.first_order_date,
    s.last_order_date,
    s.total_orders,
    s.total_revenue,
    s.total_profit,
    s.avg_order_value,
    s.customer_segment,
    s.is_active
);


SELECT *
FROM DB_gold_customer_lifetime_value
ORDER BY last_order_date DESC;




-- gold_product_performance --
TRUNCATE TABLE DB_gold_product_performance;

INSERT INTO DB_gold_product_performance
SELECT
    oi.product_id,
    sp.product_name,
    sp.category,

    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue,

    SUM(oi.line_total * 0.30) AS total_profit,

    ROUND(
        SUM(oi.line_total * 0.30)
        / NULLIF(SUM(oi.line_total), 0),
        2
    ) AS profit_margin

FROM DB_silver_order_items oi

LEFT JOIN DB_silver_products sp
    ON oi.product_id = sp.product_id
   AND sp.is_current = TRUE

WHERE oi.is_current = TRUE

GROUP BY
    oi.product_id,
    sp.product_name,
    sp.category;


SELECT *
FROM DB_gold_product_performance
ORDER BY total_revenue DESC;


-- // Product performance is a cumulative metric, so we rebuild it idempotently instead of using incremental logic to avoid historical drift.//






-- gold_customer_segment_trends(daily snapshot) --
INSERT INTO DB_gold_customer_segment_trends
SELECT
    CURRENT_DATE AS snapshot_date,
    sc.customer_segment,

    COUNT(DISTINCT CASE
        WHEN o.order_date >= CURRENT_DATE - 90
        THEN o.customer_id
    END) AS active_customers,

    COUNT(DISTINCT CASE
        WHEN o.order_date = CURRENT_DATE
        THEN o.customer_id
    END) AS new_customers,

    COUNT(DISTINCT CASE
        WHEN o.order_date < CURRENT_DATE - 90
        THEN o.customer_id
    END) AS churned_customers,

    SUM(o.total_amount) AS total_revenue,

    ROUND(
        SUM(o.total_amount)
        / NULLIF(COUNT(DISTINCT o.customer_id), 0),
        2
    ) AS avg_revenue_per_customer

FROM DB_silver_orders o

LEFT JOIN DB_silver_customers sc
    ON o.customer_id = sc.customer_id
   AND sc.is_current = TRUE
WHERE o.is_current = TRUE

-- incremental guard
AND CURRENT_DATE NOT IN (
    SELECT DISTINCT snapshot_date
    FROM DB_gold_customer_segment_trends
)
GROUP BY sc.customer_segment;

SELECT *
FROM DB_gold_customer_segment_trends
ORDER BY snapshot_date DESC, customer_segment;





