-- ========================================
-- ANYCOMPANY - ANALYSE DES TENDANCES DE VENTES
-- Phase 2.2 : Analyses Exploratoires Descriptives
-- ========================================

USE DATABASE ANYCOMPANY_LAB;
USE SCHEMA SILVER;

-- ========================================
-- 1. VUE D'ENSEMBLE DES VENTES
-- ========================================

-- Métriques globales
SELECT 
    'Vue d ensemble des ventes' AS analyse,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT transaction_id) AS unique_transactions,
    COUNT(DISTINCT region) AS regions_actives,
    MIN(transaction_date) AS premiere_vente,
    MAX(transaction_date) AS derniere_vente,
    SUM(amount) AS chiffre_affaires_total,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM financial_transactions_clean
WHERE transaction_type = 'Sale';

-- Distribution par type de transaction
SELECT 
    transaction_type,
    COUNT(*) AS nombre_transactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pourcentage,
    SUM(amount) AS montant_total,
    ROUND(AVG(amount), 2) AS montant_moyen
FROM financial_transactions_clean
GROUP BY transaction_type
ORDER BY montant_total DESC;

-- ========================================
-- 2. ÉVOLUTION TEMPORELLE DES VENTES
-- ========================================

-- Ventes par année avec croissance YoY
WITH ventes_annuelles AS (
    SELECT
        YEAR(transaction_date) AS transaction_year,
        COUNT(*) AS nombre_ventes,
        SUM(amount) AS total_ventes,
        ROUND(AVG(amount), 2) AS panier_moyen
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY YEAR(transaction_date)
)
SELECT
    transaction_year,
    nombre_ventes,
    total_ventes,
    panier_moyen,
    LAG(total_ventes) OVER (ORDER BY transaction_year) AS ventes_annee_precedente,
    ROUND(
        (total_ventes - LAG(total_ventes) OVER (ORDER BY transaction_year)) * 100.0 / 
        NULLIF(LAG(total_ventes) OVER (ORDER BY transaction_year), 0), 
        2
    ) AS croissance_yoy_pct
FROM ventes_annuelles
ORDER BY transaction_year DESC;

-- Ventes par trimestre (3 dernières années)
WITH ventes_trimestrielles AS (
    SELECT 
        YEAR(transaction_date) AS transaction_year,
        QUARTER(transaction_date) AS transaction_quarter,
        COUNT(*) AS nombre_ventes,
        SUM(amount) AS total_ventes,
        ROUND(AVG(amount), 2) AS panier_moyen
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
      AND YEAR(transaction_date) >= YEAR(CURRENT_DATE()) - 3
    GROUP BY YEAR(transaction_date), QUARTER(transaction_date)
)
SELECT *
FROM ventes_trimestrielles
ORDER BY transaction_year DESC, transaction_quarter;

-- Ventes mensuelles (12 derniers mois) avec évolution MoM
WITH ventes_mensuelles AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) AS mois,
        COUNT(*) AS nombre_ventes,
        SUM(amount) AS total_ventes,
        ROUND(AVG(amount), 2) AS panier_moyen
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
      AND transaction_date >= DATEADD(month, -12, CURRENT_DATE())
    GROUP BY DATE_TRUNC('month', transaction_date)
)
SELECT
    mois,
    nombre_ventes,
    total_ventes,
    panier_moyen,
    LAG(total_ventes) OVER (ORDER BY mois) AS ventes_mois_precedent,
    ROUND(
        (total_ventes - LAG(total_ventes) OVER (ORDER BY mois)) * 100.0 / 
        NULLIF(LAG(total_ventes) OVER (ORDER BY mois), 0), 
        2
    ) AS croissance_mom_pct
FROM ventes_mensuelles
ORDER BY mois DESC;

-- ========================================
-- 3. ANALYSE DE SAISONNALITÉ
-- ========================================

-- Ventes par mois de l'année (pattern saisonnier)
SELECT 
    MONTH(transaction_date) AS numero_mois,
    TO_CHAR(transaction_date, 'Month') AS nom_mois,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS pct_ca_annuel
FROM financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY MONTH(transaction_date), TO_CHAR(transaction_date, 'Month')
ORDER BY numero_mois;

-- Identifier les pics et creux saisonniers
WITH ventes_mensuelles AS (
    SELECT 
        TO_CHAR(transaction_date, 'Month') AS mois,
        MONTH(transaction_date) AS numero_mois,
        SUM(amount) AS total_ventes
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY TO_CHAR(transaction_date, 'Month'), MONTH(transaction_date)
),
stats AS (
    SELECT 
        AVG(total_ventes) AS moyenne,
        STDDEV(total_ventes) AS ecart_type
    FROM ventes_mensuelles
)
SELECT 
    v.mois,
    v.total_ventes,
    s.moyenne,
    CASE 
        WHEN v.total_ventes > s.moyenne + s.ecart_type THEN 'PIC SAISONNIER'
        WHEN v.total_ventes < s.moyenne - s.ecart_type THEN 'CREUX SAISONNIER'
        ELSE 'NORMAL'
    END AS classification,
    ROUND((v.total_ventes - s.moyenne) * 100.0 / s.moyenne, 2) AS ecart_moyenne_pct
FROM ventes_mensuelles v
CROSS JOIN stats s
ORDER BY v.total_ventes DESC;

-- ========================================
-- 4. PERFORMANCE PAR RÉGION
-- ========================================

-- Ventes par région avec ranking
SELECT 
    region,
    COUNT(*) AS nombre_ventes,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS pct_ca_total,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS rang_region
FROM financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY region
ORDER BY total_ventes DESC;

-- Top 10 entités (pays/entreprises) par ventes
SELECT 
    region,
    entity AS entite,
    COUNT(*) AS nombre_ventes,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY region, entity
ORDER BY total_ventes DESC
LIMIT 10;

-- Évolution régionale sur 3 ans
WITH ventes_regionales AS (
    SELECT 
        region,
        YEAR(transaction_date) AS transaction_year,
        SUM(amount) AS total_ventes
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
      AND YEAR(transaction_date) >= YEAR(CURRENT_DATE()) - 3
    GROUP BY region, YEAR(transaction_date)
)
SELECT 
    region,
    transaction_year,
    total_ventes,
    LAG(total_ventes) OVER (PARTITION BY region ORDER BY transaction_year) AS ventes_annee_precedente,
    ROUND(
        (total_ventes - LAG(total_ventes) OVER (PARTITION BY region ORDER BY transaction_year)) * 100.0 / 
        NULLIF(LAG(total_ventes) OVER (PARTITION BY region ORDER BY transaction_year), 0), 
        2
    ) AS croissance_yoy_pct
FROM ventes_regionales
ORDER BY region, transaction_year DESC;

-- ========================================
-- 5. ANALYSE PAR MÉTHODE DE PAIEMENT
-- ========================================

SELECT 
    payment_method,
    COUNT(*) AS nombre_transactions,
    SUM(amount) AS montant_total,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_transactions,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS pct_ca
FROM financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY payment_method
ORDER BY montant_total DESC;

-- ========================================
-- 6. INDICATEURS CLÉS DE PERFORMANCE (KPIs)
-- ========================================

-- KPIs globaux
SELECT 
    'KPIs Globaux' AS categorie,
    SUM(amount) AS chiffre_affaires_total,
    COUNT(*) AS total_transactions,
    ROUND(AVG(amount), 2) AS panier_moyen,
    COUNT(DISTINCT region) AS regions_actives,
    COUNT(DISTINCT entity) AS clients_uniques,
    MIN(transaction_date) AS premiere_vente,
    MAX(transaction_date) AS derniere_vente
FROM financial_transactions_clean
WHERE transaction_type = 'Sale';

-- Top 5 et Bottom 5 régions
(
    SELECT 
        'TOP 5' AS categorie,
        region,
        SUM(amount) AS total_ventes,
        COUNT(*) AS nombre_transactions
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY region
    ORDER BY total_ventes DESC
    LIMIT 5
)
UNION ALL
(
    SELECT 
        'BOTTOM 5' AS categorie,
        region,
        SUM(amount) AS total_ventes,
        COUNT(*) AS nombre_transactions
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY region
    ORDER BY total_ventes ASC
    LIMIT 5
);

-- ========================================
-- 7. DÉTECTION D'ANOMALIES
-- ========================================

-- Transactions exceptionnellement élevées (>3 écarts-types)
WITH stats AS (
    SELECT 
        AVG(amount) AS moyenne,
        STDDEV(amount) AS ecart_type
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
)
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.region,
    t.entity,
    t.amount,
    t.payment_method,
    'TRANSACTION EXCEPTIONNELLE' AS alerte,
    ROUND((t.amount - s.moyenne) / s.ecart_type, 2) AS nb_ecarts_types
FROM financial_transactions_clean t
CROSS JOIN stats s
WHERE t.transaction_type = 'Sale'
  AND t.amount > s.moyenne + 3 * s.ecart_type
ORDER BY t.amount DESC
LIMIT 20;

-- Périodes de baisse significative (>10%)
WITH ventes_mensuelles AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) AS mois,
        SUM(amount) AS total_ventes
    FROM financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY DATE_TRUNC('month', transaction_date)
),
variations AS (
    SELECT 
        mois,
        total_ventes,
        LAG(total_ventes) OVER (ORDER BY mois) AS ventes_mois_precedent,
        ROUND(
            (total_ventes - LAG(total_ventes) OVER (ORDER BY mois)) * 100.0 / 
            NULLIF(LAG(total_ventes) OVER (ORDER BY mois), 0), 
            2
        ) AS variation_pct
    FROM ventes_mensuelles
)
SELECT 
    mois,
    total_ventes,
    ventes_mois_precedent,
    variation_pct,
    CASE 
        WHEN variation_pct < -10 THEN '⚠️ ALERTE BAISSE'
        ELSE 'OK'
    END AS statut
FROM variations
WHERE variation_pct < -10
ORDER BY mois DESC;

-- ========================================
-- 8. INSIGHTS SYNTHÉTIQUES
-- ========================================

-- Résumé exécutif des ventes
SELECT 
    'RÉSUMÉ EXÉCUTIF' AS section,
    (SELECT SUM(amount) FROM financial_transactions_clean WHERE transaction_type = 'Sale') AS ca_total,
    (SELECT COUNT(*) FROM financial_transactions_clean WHERE transaction_type = 'Sale') AS total_ventes,
    (SELECT region FROM (
        SELECT region, SUM(amount) AS total 
        FROM financial_transactions_clean 
        WHERE transaction_type = 'Sale' 
        GROUP BY region 
        ORDER BY total DESC 
        LIMIT 1
    )) AS meilleure_region,
    (SELECT TO_CHAR(transaction_date, 'Month') FROM (
        SELECT transaction_date, SUM(amount) AS total 
        FROM financial_transactions_clean 
        WHERE transaction_type = 'Sale' 
        GROUP BY transaction_date, MONTH(transaction_date), TO_CHAR(transaction_date, 'Month')
        ORDER BY total DESC 
        LIMIT 1
    )) AS meilleur_mois;

-- Aperçu des campagnes marketing
SELECT * FROM marketing_campaigns_clean;