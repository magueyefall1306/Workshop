-- ========================================
-- ANYCOMPANY - CHARGEMENT DES DONNÉES
-- Phase 1 : Data Preparation & Ingestion
-- VERSION FINALE CORRIGÉE
-- ========================================

-- Créer la base de données
CREATE DATABASE IF NOT EXISTS ANYCOMPANY_LAB;
USE DATABASE ANYCOMPANY_LAB;

-- Créer les schémas
CREATE SCHEMA IF NOT EXISTS BRONZE;
CREATE SCHEMA IF NOT EXISTS SILVER;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Créer un warehouse
CREATE WAREHOUSE IF NOT EXISTS ANALYTICS_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE ANALYTICS_WH;
USE SCHEMA BRONZE;

-- Créer le stage S3
CREATE OR REPLACE STAGE S3_STAGE
  URL = 's3://logbrain-datalake/datasets/food-beverage/';

-- Vérifier les fichiers disponibles
LIST @S3_STAGE;

-- ========================================
-- CRÉATION DES TABLES BRONZE
-- ========================================

-- 1. Customer Demographics
CREATE OR REPLACE TABLE customer_demographics (
    customer_id INTEGER,
    name VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(20),
    region VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    marital_status VARCHAR(50),
    annual_income NUMBER(12,2)
);

-- 2. Customer Service Interactions
CREATE OR REPLACE TABLE customer_service_interactions (
    interaction_id VARCHAR(50),
    interaction_date DATE,
    interaction_type VARCHAR(50),
    issue_category VARCHAR(100),
    description TEXT,
    duration_minutes INTEGER,
    resolution_status VARCHAR(50),
    follow_up_required VARCHAR(10),
    customer_satisfaction INTEGER
);

-- 3. Financial Transactions
CREATE OR REPLACE TABLE financial_transactions (
    transaction_id VARCHAR(50),
    transaction_date DATE,
    transaction_type VARCHAR(50),
    amount NUMBER(12,2),
    payment_method VARCHAR(50),
    entity VARCHAR(200),
    region VARCHAR(100),
    account_code VARCHAR(50)
);

-- 4. Promotions Data
CREATE OR REPLACE TABLE promotions_data (
    promotion_id VARCHAR(50),
    product_category VARCHAR(100),
    promotion_type VARCHAR(100),
    discount_percentage NUMBER(5,2),
    start_date DATE,
    end_date DATE,
    region VARCHAR(100)
);

-- 5. Marketing Campaigns
CREATE OR REPLACE TABLE marketing_campaigns (
    campaign_id VARCHAR(50),
    campaign_name VARCHAR(200),
    campaign_type VARCHAR(100),
    product_category VARCHAR(100),
    target_audience VARCHAR(100),
    start_date DATE,
    end_date DATE,
    region VARCHAR(100),
    budget NUMBER(12,2),
    reach INTEGER,
    conversion_rate NUMBER(5,4)
);

-- 6. Product Reviews (8 colonnes)
CREATE OR REPLACE TABLE product_reviews (
    review_id INTEGER,
    product_id VARCHAR(50),
    reviewer_id VARCHAR(50),
    reviewer_name VARCHAR(100),
    rating INTEGER,
    review_date DATE,
    review_title VARCHAR(200),
    review_text TEXT
);

-- 7. Inventory
CREATE OR REPLACE TABLE inventory (
    product_id VARCHAR(50),
    product_category VARCHAR(100),
    region VARCHAR(100),
    country VARCHAR(100),
    warehouse VARCHAR(200),
    current_stock INTEGER,
    reorder_point INTEGER,
    lead_time INTEGER,
    last_restock_date DATE
);

-- 8. Store Locations
CREATE OR REPLACE TABLE store_locations (
    store_id VARCHAR(50),
    store_name VARCHAR(200),
    store_type VARCHAR(50),
    region VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    address VARCHAR(300),
    postal_code INTEGER,
    square_footage NUMBER(10,2),
    employee_count INTEGER
);

-- 9. Logistics and Shipping
CREATE OR REPLACE TABLE logistics_and_shipping (
    shipment_id VARCHAR(50),
    order_id VARCHAR(50),
    ship_date DATE,
    estimated_delivery DATE,
    shipping_method VARCHAR(50),
    status VARCHAR(50),
    shipping_cost NUMBER(10,2),
    destination_region VARCHAR(100),
    destination_country VARCHAR(100),
    carrier VARCHAR(200)
);

-- 10. Supplier Information
CREATE OR REPLACE TABLE supplier_information (
    supplier_id VARCHAR(50),
    supplier_name VARCHAR(200),
    product_category VARCHAR(100),
    region VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    lead_time INTEGER,
    reliability_score NUMBER(5,2),
    quality_rating VARCHAR(10)
);

-- 11. Employee Records
CREATE OR REPLACE TABLE employee_records (
    employee_id VARCHAR(50),
    name VARCHAR(100),
    date_of_birth DATE,
    hire_date DATE,
    department VARCHAR(100),
    job_title VARCHAR(200),
    salary NUMBER(12,2),
    region VARCHAR(100),
    country VARCHAR(100),
    email VARCHAR(200)
);

-- ========================================
-- CHARGEMENT DES DONNÉES CSV
-- ========================================

-- 1. Customer Demographics
COPY INTO customer_demographics
FROM @S3_STAGE/customer_demographics.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- 2. Customer Service Interactions
COPY INTO customer_service_interactions
FROM @S3_STAGE/customer_service_interactions.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
    ESCAPE_UNENCLOSED_FIELD = NONE
)
ON_ERROR = CONTINUE;

-- 3. Financial Transactions
COPY INTO financial_transactions
FROM @S3_STAGE/financial_transactions.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- 4. Promotions Data
COPY INTO promotions_data
FROM @S3_STAGE/promotions-data.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- 5. Marketing Campaigns
COPY INTO marketing_campaigns
FROM @S3_STAGE/marketing_campaigns.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- 6. Product Reviews
COPY INTO product_reviews
FROM @S3_STAGE/product_reviews.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
    ESCAPE_UNENCLOSED_FIELD = NONE
    SKIP_BLANK_LINES = TRUE
)
ON_ERROR = CONTINUE;

-- 7. Logistics and Shipping
COPY INTO logistics_and_shipping
FROM @S3_STAGE/logistics_and_shipping.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- 8. Supplier Information
COPY INTO supplier_information
FROM @S3_STAGE/supplier_information.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- 9. Employee Records
COPY INTO employee_records
FROM @S3_STAGE/employee_records.csv
FILE_FORMAT = (
    TYPE = 'CSV' 
    FIELD_DELIMITER = ',' 
    SKIP_HEADER = 1 
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
    NULL_IF = ('NULL', 'null', '')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
)
ON_ERROR = CONTINUE;

-- ========================================
-- CHARGEMENT DES DONNÉES JSON
-- ========================================

-- 10. Inventory - Méthode 1 : MATCH_BY_COLUMN_NAME (essayez d'abord celle-ci)
COPY INTO inventory
FROM @S3_STAGE/inventory.json
FILE_FORMAT = (TYPE = 'JSON')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = CONTINUE;

-- Si la méthode ci-dessus ne fonctionne pas, utilisez cette alternative :
/*
COPY INTO inventory (
    product_id,
    product_category,
    region,
    country,
    warehouse,
    current_stock,
    reorder_point,
    lead_time,
    last_restock_date
)
FROM (
    SELECT 
        $1:product_id::VARCHAR(50),
        $1:product_category::VARCHAR(100),
        $1:region::VARCHAR(100),
        $1:country::VARCHAR(100),
        $1:warehouse::VARCHAR(200),
        $1:current_stock::INTEGER,
        $1:reorder_point::INTEGER,
        $1:lead_time::INTEGER,
        $1:last_restock_date::DATE
    FROM @S3_STAGE/inventory.json
)
FILE_FORMAT = (TYPE = 'JSON')
ON_ERROR = CONTINUE;
*/

-- 11. Store Locations - Méthode 1 : MATCH_BY_COLUMN_NAME (essayez d'abord celle-ci)
COPY INTO store_locations
FROM @S3_STAGE/store_locations.json
FILE_FORMAT = (TYPE = 'JSON')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = CONTINUE;

-- Si la méthode ci-dessus ne fonctionne pas, utilisez cette alternative :
/*
COPY INTO store_locations (
    store_id,
    store_name,
    store_type,
    region,
    country,
    city,
    address,
    postal_code,
    square_footage,
    employee_count
)
FROM (
    SELECT 
        $1:store_id::VARCHAR(50),
        $1:store_name::VARCHAR(200),
        $1:store_type::VARCHAR(50),
        $1:region::VARCHAR(100),
        $1:country::VARCHAR(100),
        $1:city::VARCHAR(100),
        $1:address::VARCHAR(300),
        $1:postal_code::INTEGER,
        $1:square_footage::NUMBER(10,2),
        $1:employee_count::INTEGER
    FROM @S3_STAGE/store_locations.json
)
FILE_FORMAT = (TYPE = 'JSON')
ON_ERROR = CONTINUE;
*/

-- ========================================
-- VÉRIFICATIONS POST-CHARGEMENT
-- ========================================

-- Vérifier les volumes chargés
SELECT 'customer_demographics' AS table_name, COUNT(*) AS row_count FROM customer_demographics
UNION ALL SELECT 'customer_service_interactions', COUNT(*) FROM customer_service_interactions
UNION ALL SELECT 'financial_transactions', COUNT(*) FROM financial_transactions
UNION ALL SELECT 'promotions_data', COUNT(*) FROM promotions_data
UNION ALL SELECT 'marketing_campaigns', COUNT(*) FROM marketing_campaigns
UNION ALL SELECT 'product_reviews', COUNT(*) FROM product_reviews
UNION ALL SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL SELECT 'store_locations', COUNT(*) FROM store_locations
UNION ALL SELECT 'logistics_and_shipping', COUNT(*) FROM logistics_and_shipping
UNION ALL SELECT 'supplier_information', COUNT(*) FROM supplier_information
UNION ALL SELECT 'employee_records', COUNT(*) FROM employee_records
ORDER BY table_name;

-- Vérifier spécifiquement les tables JSON
SELECT 'inventory' AS table_name, * FROM inventory LIMIT 5;
SELECT 'store_locations' AS table_name, * FROM store_locations LIMIT 5;

-- ========================================
-- STATISTIQUES DE QUALITÉ DES DONNÉES
-- ========================================

-- Résumé de qualité pour toutes les tables
SELECT 
    'customer_demographics' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_ids,
    COUNT(*) - COUNT(annual_income) AS null_income
FROM customer_demographics
UNION ALL SELECT 
    'product_reviews',
    COUNT(*),
    COUNT(DISTINCT review_id),
    COUNT(*) - COUNT(review_text)
FROM product_reviews
UNION ALL SELECT 
    'inventory',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(current_stock)
FROM inventory
UNION ALL SELECT 
    'store_locations',
    COUNT(*),
    COUNT(DISTINCT store_id),
    COUNT(*) - COUNT(employee_count)
FROM store_locations;

-- Vérifier les plages de dates
SELECT 
    'financial_transactions' AS table_name,
    MIN(transaction_date) AS min_date,
    MAX(transaction_date) AS max_date,
    COUNT(*) AS total_transactions
FROM financial_transactions
UNION ALL SELECT 
    'marketing_campaigns',
    MIN(start_date),
    MAX(end_date),
    COUNT(*)
FROM marketing_campaigns
UNION ALL SELECT 
    'product_reviews',
    MIN(review_date),
    MAX(review_date),
    COUNT(*)
FROM product_reviews;

-- ========================================
-- DIAGNOSTIC DES ERREURS (si nécessaire)
-- ========================================

-- Pour voir les détails des erreurs de chargement d'une table spécifique :
-- Remplacez TABLE_NAME par le nom de la table à diagnostiquer
-- SELECT * FROM TABLE(VALIDATE(TABLE_NAME, JOB_ID => '_last'));

-- Exemple :
-- SELECT * FROM TABLE(VALIDATE(product_reviews, JOB_ID => '_last'));
-- SELECT * FROM TABLE(VALIDATE(inventory, JOB_ID => '_last'));

-- ========================================
-- FIN DU SCRIPT
-- ========================================

-- Résumé final
SELECT 
    'CHARGEMENT TERMINÉ' AS status,
    (SELECT COUNT(*) FROM customer_demographics) + 
    (SELECT COUNT(*) FROM customer_service_interactions) +
    (SELECT COUNT(*) FROM financial_transactions) +
    (SELECT COUNT(*) FROM promotions_data) +
    (SELECT COUNT(*) FROM marketing_campaigns) +
    (SELECT COUNT(*) FROM product_reviews) +
    (SELECT COUNT(*) FROM inventory) +
    (SELECT COUNT(*) FROM store_locations) +
    (SELECT COUNT(*) FROM logistics_and_shipping) +
    (SELECT COUNT(*) FROM supplier_information) +
    (SELECT COUNT(*) FROM employee_records) AS total_rows_loaded;