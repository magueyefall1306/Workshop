-- ========================================
-- ANYCOMPANY - NETTOYAGE DES DONNÉES
-- Phase 1 : BRONZE → SILVER
-- ========================================

USE DATABASE ANYCOMPANY_LAB;
USE SCHEMA SILVER;

-- ========================================
-- 1. CUSTOMER DEMOGRAPHICS CLEAN
-- ========================================
CREATE OR REPLACE TABLE customer_demographics_clean AS
SELECT 
    customer_id,
    TRIM(name) AS name,
    date_of_birth,
    CASE 
        WHEN gender IN ('Male', 'Female', 'Other') THEN gender
        ELSE 'Unknown'
    END AS gender,
    TRIM(region) AS region,
    TRIM(country) AS country,
    TRIM(city) AS city,
    TRIM(marital_status) AS marital_status,
    CASE 
        WHEN annual_income > 0 THEN annual_income
        ELSE NULL
    END AS annual_income,
    YEAR(CURRENT_DATE()) - YEAR(date_of_birth) AS age
FROM BRONZE.customer_demographics
WHERE customer_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY name) = 1;

-- ========================================
-- 2. FINANCIAL TRANSACTIONS CLEAN
-- ========================================
CREATE OR REPLACE TABLE financial_transactions_clean AS
SELECT 
    transaction_id,
    transaction_date,
    TRIM(transaction_type) AS transaction_type,
    ABS(amount) AS amount,
    TRIM(payment_method) AS payment_method,
    TRIM(entity) AS entity,
    TRIM(region) AS region,
    TRIM(account_code) AS account_code,
    YEAR(transaction_date) AS transaction_year,
    QUARTER(transaction_date) AS transaction_quarter,
    MONTH(transaction_date) AS transaction_month
FROM BRONZE.financial_transactions
WHERE transaction_id IS NOT NULL
  AND transaction_date IS NOT NULL
  AND amount IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_date DESC) = 1;

-- ========================================
-- 3. PROMOTIONS CLEAN
-- ========================================
CREATE OR REPLACE TABLE promotions_clean AS
SELECT 
    promotion_id,
    TRIM(product_category) AS product_category,
    TRIM(promotion_type) AS promotion_type,
    CASE 
        WHEN discount_percentage BETWEEN 0 AND 1 THEN discount_percentage
        ELSE NULL
    END AS discount_percentage,
    start_date,
    end_date,
    TRIM(region) AS region,
    DATEDIFF(day, start_date, end_date) AS promotion_duration_days
FROM BRONZE.promotions_data
WHERE promotion_id IS NOT NULL
  AND start_date IS NOT NULL
  AND end_date IS NOT NULL
  AND start_date <= end_date
QUALIFY ROW_NUMBER() OVER (PARTITION BY promotion_id ORDER BY start_date) = 1;

-- ========================================
-- 4. MARKETING CAMPAIGNS CLEAN
-- ========================================
CREATE OR REPLACE TABLE marketing_campaigns_clean AS
SELECT 
    campaign_id,
    TRIM(campaign_name) AS campaign_name,
    TRIM(campaign_type) AS campaign_type,
    TRIM(product_category) AS product_category,
    TRIM(target_audience) AS target_audience,
    start_date,
    end_date,
    TRIM(region) AS region,
    CASE 
        WHEN budget > 0 THEN budget
        ELSE NULL
    END AS budget,
    CASE 
        WHEN reach > 0 THEN reach
        ELSE NULL
    END AS reach,
    CASE 
        WHEN conversion_rate BETWEEN 0 AND 1 THEN conversion_rate
        ELSE NULL
    END AS conversion_rate,
    DATEDIFF(day, start_date, end_date) AS campaign_duration_days,
    CASE 
        WHEN reach > 0 AND conversion_rate > 0 
        THEN budget / (reach * conversion_rate)
        ELSE NULL
    END AS cost_per_acquisition
FROM BRONZE.marketing_campaigns
WHERE campaign_id IS NOT NULL
  AND start_date IS NOT NULL
  AND end_date IS NOT NULL
  AND start_date <= end_date
QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY start_date) = 1;

-- ========================================
-- 5. PRODUCT REVIEWS CLEAN
-- ========================================
CREATE OR REPLACE TABLE product_reviews_clean AS
SELECT 
    review_id,
    TRIM(product_id) AS product_id,
    TRIM(reviewer_id) AS reviewer_id,
    TRIM(reviewer_name) AS reviewer_name,
    CASE 
        WHEN rating BETWEEN 1 AND 5 THEN rating
        ELSE NULL
    END AS rating,
    review_date,
    TRIM(review_title) AS review_title,
    TRIM(review_text) AS review_text,
    CASE 
        WHEN rating >= 4 THEN 'Positive'
        WHEN rating = 3 THEN 'Neutral'
        WHEN rating <= 2 THEN 'Negative'
        ELSE 'Unknown'
    END AS sentiment
FROM BRONZE.product_reviews
WHERE review_id IS NOT NULL
  AND product_id IS NOT NULL
  AND review_date IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_date DESC) = 1;

-- ========================================
-- 6. CUSTOMER SERVICE INTERACTIONS CLEAN
-- ========================================
CREATE OR REPLACE TABLE customer_service_interactions_clean AS
SELECT 
    interaction_id,
    interaction_date,
    TRIM(interaction_type) AS interaction_type,
    TRIM(issue_category) AS issue_category,
    TRIM(description) AS description,
    CASE 
        WHEN duration_minutes > 0 THEN duration_minutes
        ELSE NULL
    END AS duration_minutes,
    TRIM(resolution_status) AS resolution_status,
    TRIM(follow_up_required) AS follow_up_required,
    CASE 
        WHEN customer_satisfaction BETWEEN 1 AND 5 THEN customer_satisfaction
        ELSE NULL
    END AS customer_satisfaction
FROM BRONZE.customer_service_interactions
WHERE interaction_id IS NOT NULL
  AND interaction_date IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY interaction_id ORDER BY interaction_date DESC) = 1;

-- ========================================
-- 7. INVENTORY CLEAN
-- ========================================
CREATE OR REPLACE TABLE inventory_clean AS
SELECT 
    TRIM(product_id) AS product_id,
    TRIM(product_category) AS product_category,
    TRIM(region) AS region,
    TRIM(country) AS country,
    TRIM(warehouse) AS warehouse,
    CASE 
        WHEN current_stock >= 0 THEN current_stock
        ELSE 0
    END AS current_stock,
    CASE 
        WHEN reorder_point > 0 THEN reorder_point
        ELSE NULL
    END AS reorder_point,
    CASE 
        WHEN lead_time > 0 THEN lead_time
        ELSE NULL
    END AS lead_time,
    last_restock_date,
    CASE 
        WHEN current_stock <= reorder_point THEN TRUE
        ELSE FALSE
    END AS is_low_stock
FROM BRONZE.inventory
WHERE product_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id, warehouse ORDER BY last_restock_date DESC) = 1;

-- ========================================
-- 8. STORE LOCATIONS CLEAN
-- ========================================
CREATE OR REPLACE TABLE store_locations_clean AS
SELECT 
    TRIM(store_id) AS store_id,
    TRIM(store_name) AS store_name,
    TRIM(store_type) AS store_type,
    TRIM(region) AS region,
    TRIM(country) AS country,
    TRIM(city) AS city,
    TRIM(address) AS address,
    postal_code,
    CASE 
        WHEN square_footage > 0 THEN square_footage
        ELSE NULL
    END AS square_footage,
    CASE 
        WHEN employee_count > 0 THEN employee_count
        ELSE NULL
    END AS employee_count
FROM BRONZE.store_locations
WHERE store_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY store_name) = 1;

-- ========================================
-- 9. LOGISTICS AND SHIPPING CLEAN
-- ========================================
CREATE OR REPLACE TABLE logistics_and_shipping_clean AS
SELECT 
    shipment_id,
    order_id,
    ship_date,
    estimated_delivery,
    TRIM(shipping_method) AS shipping_method,
    TRIM(status) AS status,
    CASE 
        WHEN shipping_cost >= 0 THEN shipping_cost
        ELSE NULL
    END AS shipping_cost,
    TRIM(destination_region) AS destination_region,
    TRIM(destination_country) AS destination_country,
    TRIM(carrier) AS carrier,
    DATEDIFF(day, ship_date, estimated_delivery) AS estimated_delivery_days
FROM BRONZE.logistics_and_shipping
WHERE shipment_id IS NOT NULL
  AND ship_date IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY shipment_id ORDER BY ship_date DESC) = 1;

-- ========================================
-- 10. SUPPLIER INFORMATION CLEAN
-- ========================================
CREATE OR REPLACE TABLE supplier_information_clean AS
SELECT 
    supplier_id,
    TRIM(supplier_name) AS supplier_name,
    TRIM(product_category) AS product_category,
    TRIM(region) AS region,
    TRIM(country) AS country,
    TRIM(city) AS city,
    CASE 
        WHEN lead_time > 0 THEN lead_time
        ELSE NULL
    END AS lead_time,
    CASE 
        WHEN reliability_score BETWEEN 0 AND 1 THEN reliability_score
        ELSE NULL
    END AS reliability_score,
    TRIM(quality_rating) AS quality_rating
FROM BRONZE.supplier_information
WHERE supplier_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY supplier_name) = 1;

-- ========================================
-- 11. EMPLOYEE RECORDS CLEAN
-- ========================================
CREATE OR REPLACE TABLE employee_records_clean AS
SELECT 
    employee_id,
    TRIM(name) AS name,
    date_of_birth,
    hire_date,
    TRIM(department) AS department,
    TRIM(job_title) AS job_title,
    CASE 
        WHEN salary > 0 THEN salary
        ELSE NULL
    END AS salary,
    TRIM(region) AS region,
    TRIM(country) AS country,
    LOWER(TRIM(email)) AS email,
    DATEDIFF(year, hire_date, CURRENT_DATE()) AS years_of_service
FROM BRONZE.employee_records
WHERE employee_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY hire_date) = 1;

-- ========================================
-- VÉRIFICATIONS FINALES
-- ========================================
SELECT 'Nettoyage terminé avec succès!' AS status;

-- Compter les lignes nettoyées
SELECT 'customer_demographics' AS table_name, COUNT(*) AS clean_count FROM customer_demographics_clean
UNION ALL SELECT 'financial_transactions', COUNT(*) FROM financial_transactions_clean
UNION ALL SELECT 'promotions', COUNT(*) FROM promotions_clean
UNION ALL SELECT 'marketing_campaigns', COUNT(*) FROM marketing_campaigns_clean
UNION ALL SELECT 'product_reviews', COUNT(*) FROM product_reviews_clean
ORDER BY table_name;