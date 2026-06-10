# Snowflake Data Pipeline Project

## Overview

This project implements an end-to-end ETL Data Pipeline in Snowflake using the Medallion Architecture (Bronze, Silver, Gold).

The pipeline ingests CSV files from an external stage, processes and cleanses data, applies Slowly Changing Dimension (SCD Type 2) logic, and generates business-ready analytics tables.

## Architecture

Bronze Layer → Raw Data Ingestion

Silver Layer → Data Cleansing & Transformation

Gold Layer → Business Aggregations & Reporting

## Dataset

The pipeline processes:

* Customers
* Products
* Orders
* Order Items

## Technologies Used

* Snowflake
* SQL
* ETL Pipeline
* SCD Type 2
* Data Warehousing

## Project Structure

project/
│
├── sql/
│   ├── 1_file_format.sql
│   ├── 2_bronze_create.sql
│   ├── 3_bronze_load.sql
│   ├── 4_archive_file.sql
│   ├── 5_silver_create.sql
│   ├── 6_silver_load.sql
│   ├── 7_gold_create.sql
│   └── 8_gold_load.sql
│
├── README.md
├── requirements.txt
└── .gitignore

## Pipeline Flow

1. Create file format
2. Load source CSV files into Bronze tables
3. Generate row hashes
4. Archive processed files
5. Apply SCD Type 2 transformations in Silver layer
6. Build Gold reporting tables
7. Generate business KPIs

## Gold Layer Reports

### Daily Sales Summary

* Total Orders
* Revenue
* Units Sold
* Average Order Value
* Cancellation Rate

### Customer Lifetime Value

* Revenue per Customer
* Profit per Customer
* Customer Activity

### Product Performance

* Revenue
* Profit
* Units Sold
* Profit Margin

### Customer Segment Trends

* Active Customers
* New Customers
* Churned Customers
* Segment Revenue

## Author

Divya Borkar
