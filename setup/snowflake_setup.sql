-- ===== PART 1: run as ACCOUNTADMIN in a Snowsight worksheet =====
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS OLIST;
CREATE SCHEMA   IF NOT EXISTS OLIST.RAW;        -- raw CSVs land here
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;

-- ===== PART 2: load the 8 CSVs into OLIST.RAW =====
-- Snowsight -> Data -> Add Data -> Load data into a table. Name each table like the file (without .csv):
--   olist_customers_dataset, olist_orders_dataset, olist_order_items_dataset,
--   olist_order_payments_dataset, olist_order_reviews_dataset, olist_products_dataset,
--   olist_sellers_dataset, product_category_name_translation
-- (olist_geolocation_dataset is not used.)
-- For olist_order_reviews_dataset set "field optionally enclosed by" to a double quote:
-- review comments contain commas and line breaks.

-- ===== PART 3: role for dbt (run AFTER loading, so the grants cover the loaded tables) =====
USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS TRANSFORMER;
GRANT ROLE TRANSFORMER TO USER <YOUR_SNOWFLAKE_USERNAME>;          -- replace the placeholder
GRANT USAGE, OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORMER;
GRANT ALL ON DATABASE OLIST TO ROLE TRANSFORMER;                    -- includes CREATE SCHEMA, so dbt can create its schemas
GRANT ALL ON SCHEMA OLIST.RAW TO ROLE TRANSFORMER;
GRANT ALL ON ALL TABLES IN SCHEMA OLIST.RAW TO ROLE TRANSFORMER;

-- ===== PART 4: key-pair login for dbt (Snowflake enforces MFA on password logins) =====
-- Generate the key on your computer first (Git Bash on Windows, or any macOS/Linux terminal):
--   openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 aes-256-cbc -inform PEM -out rsa_key.p8
--   openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
-- Keep rsa_key.p8 OUTSIDE the git repo (for example ~/.snowflake/). Never commit it.
-- Paste the contents of rsa_key.pub WITHOUT the BEGIN/END lines:
ALTER USER <YOUR_SNOWFLAKE_USERNAME> SET RSA_PUBLIC_KEY = '<paste public key here>';
