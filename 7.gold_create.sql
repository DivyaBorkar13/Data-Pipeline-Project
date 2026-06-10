-- gold_daily_sales_summary --
CREATE TABLE IF NOT EXISTS DB_gold_daily_sales_summary (
    order_date DATE,
    total_orders NUMBER,
    total_revenue NUMBER,
    total_units_sold NUMBER,
    avg_order_value NUMBER,
    cancelled_orders NUMBER,
    cancellation_rate FLOAT
);


-- gold_customer_lifetime_value --
CREATE TABLE IF NOT EXISTS DB_gold_customer_lifetime_value (
    customer_id NUMBER,
    first_order_date DATE,
    last_order_date DATE,
    total_orders NUMBER,
    total_revenue NUMBER,
    total_profit NUMBER,
    avg_order_value FLOAT,
    customer_segment STRING,
    is_active BOOLEAN
);



-- gold_product_performance --
CREATE TABLE IF NOT EXISTS DB_gold_product_performance (
    product_id INT,
    product_name STRING,
    category STRING,
    total_orders INT,
    total_units_sold INT,
    total_revenue NUMBER(12,2),
    total_profit NUMBER(12,2),
    profit_margin FLOAT
);



-- gold_customer_segment_trends(daily snapshot) --
CREATE TABLE IF NOT EXISTS DB_gold_customer_segment_trends (
    snapshot_date DATE,
    customer_segment STRING,
    active_customers INT,
    new_customers INT,
    churned_customers INT,
    total_revenue NUMBER(12,2),
    avg_revenue_per_customer NUMBER(12,2)
);















