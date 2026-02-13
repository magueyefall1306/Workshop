-- ========================================
-- ANYCOMPANY - ANALYSE PERFORMANCE MARKETING
-- Phase 2.3 : Marketing et Performance Commerciale
-- ========================================

USE DATABASE ANYCOMPANY_LAB;
USE SCHEMA SILVER;

-- ========================================
-- 1. VUE D'ENSEMBLE DES CAMPAGNES MARKETING
-- ========================================

-- Statistiques globales
SELECT 
    'Vue d ensemble marketing' AS analyse,
    COUNT(*) AS total_campagnes,
    COUNT(DISTINCT product_category) AS categories_ciblees,
    COUNT(DISTINCT campaign_type) AS types_campagnes,
    COUNT(DISTINCT target_audience) AS segments_audience,
    COUNT(DISTINCT region) AS regions_couvertes,
    SUM(budget) AS budget_total_investi,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS taux_conversion_moyen_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen,
    MIN(start_date) AS premiere_campagne,
    MAX(end_date) AS derniere_campagne
FROM marketing_campaigns_clean;

-- Distribution par type de campagne
SELECT 
    campaign_type,
    COUNT(*) AS nombre_campagnes,
    SUM(budget) AS budget_total,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS taux_conversion_moyen_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_campagnes,
    ROUND(SUM(budget) * 100.0 / SUM(SUM(budget)) OVER(), 2) AS pct_budget
FROM marketing_campaigns_clean
GROUP BY campaign_type
ORDER BY budget_total DESC;

-- Distribution par catégorie de produit
SELECT 
    product_category,
    COUNT(*) AS nombre_campagnes,
    SUM(budget) AS budget_investi,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS taux_conversion_moyen_pct,
    ROUND(SUM(budget) * 100.0 / SUM(SUM(budget)) OVER(), 2) AS pct_budget
FROM marketing_campaigns_clean
GROUP BY product_category
ORDER BY budget_investi DESC;

-- ========================================
-- 2. PERFORMANCE PAR TYPE DE CAMPAGNE
-- ========================================

-- ROI et efficacité par type
SELECT 
    campaign_type,
    COUNT(*) AS campagnes,
    SUM(budget) AS budget_total,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen,
    ROUND(SUM(reach * conversion_rate), 0) AS conversions_estimees,
    ROUND(SUM(budget) / NULLIF(SUM(reach * conversion_rate), 0), 2) AS cpa_global,
    CASE 
        WHEN AVG(conversion_rate) > 0.08 THEN '⭐⭐⭐⭐⭐ EXCELLENT'
        WHEN AVG(conversion_rate) > 0.06 THEN '⭐⭐⭐⭐ TRÈS BON'
        WHEN AVG(conversion_rate) > 0.05 THEN '⭐⭐⭐ BON'
        ELSE '⭐⭐ À AMÉLIORER'
    END AS evaluation
FROM marketing_campaigns_clean
GROUP BY campaign_type
ORDER BY conversion_moyenne_pct DESC;

-- ========================================
-- 3. TOP & BOTTOM PERFORMERS
-- ========================================

-- Top 15 campagnes les plus performantes
SELECT 
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    target_audience,
    region,
    budget,
    reach,
    ROUND(conversion_rate * 100, 2) AS conversion_pct,
    ROUND(reach * conversion_rate, 0) AS conversions_estimees,
    ROUND(cost_per_acquisition, 2) AS cpa,
    start_date,
    end_date,
    campaign_duration_days
FROM marketing_campaigns_clean
WHERE reach > 0 AND conversion_rate > 0
ORDER BY conversion_rate DESC, cost_per_acquisition ASC
LIMIT 15;

-- Bottom 10 campagnes (CPA élevé)
SELECT 
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    budget,
    ROUND(conversion_rate * 100, 2) AS conversion_pct,
    ROUND(cost_per_acquisition, 2) AS cpa,
    '⚠️ À OPTIMISER' AS statut
FROM marketing_campaigns_clean
WHERE cost_per_acquisition IS NOT NULL
  AND budget > 300000
ORDER BY cost_per_acquisition DESC
LIMIT 10;

-- ========================================
-- 4. PERFORMANCE PAR AUDIENCE CIBLE
-- ========================================

-- Analyse par segment d'audience
SELECT 
    target_audience,
    COUNT(*) AS nombre_campagnes,
    SUM(budget) AS budget_total,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(SUM(reach * conversion_rate), 0) AS conversions_totales,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen,
    ROUND(SUM(budget) / NULLIF(SUM(reach * conversion_rate), 0), 2) AS cpa_global,
    CASE 
        WHEN AVG(conversion_rate) > 0.08 THEN ' AUDIENCE PREMIUM'
        WHEN AVG(conversion_rate) > 0.06 THEN '✅ BONNE AUDIENCE'
        ELSE '➡️ AUDIENCE STANDARD'
    END AS classification
FROM marketing_campaigns_clean
GROUP BY target_audience
ORDER BY conversions_totales DESC;

-- Meilleure catégorie par audience
SELECT 
    target_audience,
    product_category,
    COUNT(*) AS campagnes_lancees,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    SUM(budget) AS budget_investi,
    SUM(reach) AS reach_total
FROM marketing_campaigns_clean
GROUP BY target_audience, product_category
HAVING COUNT(*) >= 2
ORDER BY target_audience, conversion_moyenne_pct DESC;

-- ========================================
-- 5. ÉVOLUTION TEMPORELLE
-- ========================================

-- Investissements par année
SELECT 
    YEAR(start_date) AS annee,
    COUNT(*) AS nombre_campagnes,
    SUM(budget) AS budget_total,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(SUM(budget) / COUNT(*), 2) AS budget_moyen_par_campagne,
    LAG(SUM(budget)) OVER (ORDER BY YEAR(start_date)) AS budget_annee_precedente,
    ROUND(
        (SUM(budget) - LAG(SUM(budget)) OVER (ORDER BY YEAR(start_date))) * 100.0 / 
        NULLIF(LAG(SUM(budget)) OVER (ORDER BY YEAR(start_date)), 0), 
    2) AS evolution_budget_yoy_pct
FROM marketing_campaigns_clean
GROUP BY YEAR(start_date)
ORDER BY annee DESC;

-- Performance par trimestre (3 dernières années)
SELECT 
    YEAR(start_date) AS annee,
    QUARTER(start_date) AS trimestre,
    COUNT(*) AS campagnes,
    SUM(budget) AS budget_total,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct
FROM marketing_campaigns_clean
WHERE YEAR(start_date) >= YEAR(CURRENT_DATE()) - 3
GROUP BY YEAR(start_date), QUARTER(start_date)
ORDER BY annee DESC, trimestre DESC;

-- ========================================
-- 6. PERFORMANCE RÉGIONALE
-- ========================================

-- Analyse par région
SELECT 
    region,
    COUNT(*) AS nombre_campagnes,
    SUM(budget) AS budget_total,
    SUM(reach) AS reach_total,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(SUM(reach * conversion_rate), 0) AS conversions_estimees,
    ROUND(SUM(budget) / NULLIF(SUM(reach * conversion_rate), 0), 2) AS cpa_global,
    RANK() OVER (ORDER BY SUM(reach * conversion_rate) DESC) AS rang_performance
FROM marketing_campaigns_clean
GROUP BY region
ORDER BY conversions_estimees DESC;

-- Types de campagnes par région
SELECT 
    region,
    campaign_type,
    COUNT(*) AS campagnes_lancees,
    SUM(budget) AS budget_investi,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct
FROM marketing_campaigns_clean
GROUP BY region, campaign_type
ORDER BY region, budget_investi DESC;

-- ========================================
-- 7. EFFICACITÉ DES INVESTISSEMENTS
-- ========================================

-- Analyse par tranche de budget
WITH tranches_budget AS (
    SELECT 
        *,
        CASE 
            WHEN budget < 200000 THEN 'Petit Budget (<200K)'
            WHEN budget < 400000 THEN 'Budget Moyen (200K-400K)'
            ELSE 'Gros Budget (400K+)'
        END AS tranche_budget
    FROM marketing_campaigns_clean
)
SELECT 
    tranche_budget,
    COUNT(*) AS nombre_campagnes,
    ROUND(AVG(budget), 2) AS budget_moyen,
    ROUND(AVG(reach), 0) AS reach_moyen,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen
FROM tranches_budget
GROUP BY tranche_budget
ORDER BY 
    CASE tranche_budget
        WHEN 'Petit Budget (<200K)' THEN 1
        WHEN 'Budget Moyen (200K-400K)' THEN 2
        ELSE 3
    END;

-- ROI estimé (hypothèse: valeur moyenne conversion = $100)
WITH roi_campagnes AS (
    SELECT 
        campaign_id,
        campaign_name,
        campaign_type,
        product_category,
        budget,
        reach,
        conversion_rate,
        cost_per_acquisition,
        ROUND(reach * conversion_rate * 100, 2) AS revenus_estimes,
        ROUND((reach * conversion_rate * 100 - budget) / NULLIF(budget, 0) * 100, 2) AS roi_pct
    FROM marketing_campaigns_clean
    WHERE reach > 0 AND conversion_rate > 0
)
SELECT 
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    budget,
    revenus_estimes,
    roi_pct,
    CASE 
        WHEN roi_pct > 50 THEN '💰 EXCELLENT ROI'
        WHEN roi_pct > 0 THEN '✅ ROI POSITIF'
        WHEN roi_pct > -25 THEN '⚠️ ROI MARGINAL'
        ELSE '❌ ROI NÉGATIF'
    END AS categorie_roi
FROM roi_campagnes
ORDER BY roi_pct DESC
LIMIT 25;

-- ========================================
-- 8. CORRÉLATION CAMPAGNES ↔ VENTES
-- ========================================

-- Créer vue temporaire des ventes pendant campagnes
CREATE OR REPLACE TEMPORARY TABLE ventes_avec_campagnes AS
SELECT 
    t.*,
    c.campaign_id,
    c.campaign_name,
    c.campaign_type,
    c.product_category AS campagne_categorie,
    c.budget AS campagne_budget,
    c.conversion_rate
FROM financial_transactions_clean t
LEFT JOIN marketing_campaigns_clean c
    ON t.region = c.region
    AND t.transaction_date BETWEEN c.start_date AND c.end_date
WHERE t.transaction_type = 'Sale';

-- Ventes pendant vs hors campagnes
SELECT 
    CASE 
        WHEN campaign_id IS NOT NULL THEN 'Pendant Campagne'
        ELSE 'Hors Campagne'
    END AS statut_campagne,
    COUNT(*) AS nombre_ventes,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_ventes,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS pct_ca
FROM ventes_avec_campagnes
GROUP BY statut_campagne
ORDER BY total_ventes DESC;

-- Impact par type de campagne sur les ventes
SELECT 
    campaign_type,
    COUNT(DISTINCT campaign_id) AS campagnes_uniques,
    COUNT(*) AS ventes_pendant_campagnes,
    SUM(amount) AS ca_total,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(AVG(campagne_budget), 2) AS budget_moyen_campagne
FROM ventes_avec_campagnes
WHERE campaign_id IS NOT NULL
GROUP BY campaign_type
ORDER BY ca_total DESC;

-- ========================================
-- 9. RECOMMANDATIONS STRATÉGIQUES
-- ========================================

-- Campagnes à répliquer (haute performance + faible coût)
SELECT 
    'CAMPAGNES À RÉPLIQUER' AS recommandation,
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    target_audience,
    region,
    budget,
    ROUND(conversion_rate * 100, 2) AS conversion_pct,
    ROUND(cost_per_acquisition, 2) AS cpa
FROM marketing_campaigns_clean
WHERE conversion_rate > (SELECT AVG(conversion_rate) * 1.5 FROM marketing_campaigns_clean)
  AND cost_per_acquisition < (SELECT AVG(cost_per_acquisition) FROM marketing_campaigns_clean WHERE cost_per_acquisition > 0)
ORDER BY conversion_rate DESC
LIMIT 10;

-- Optimisation allocation budgétaire
SELECT 
    campaign_type,
    SUM(budget) AS budget_actuel,
    ROUND(SUM(budget) * 100.0 / SUM(SUM(budget)) OVER(), 2) AS pct_budget_actuel,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen,
    CASE 
        WHEN AVG(conversion_rate) > (SELECT AVG(conversion_rate) * 1.2 FROM marketing_campaigns_clean) 
        THEN '⬆️ AUGMENTER BUDGET (+20%)'
        WHEN AVG(conversion_rate) < (SELECT AVG(conversion_rate) * 0.8 FROM marketing_campaigns_clean)
        THEN '⬇️ RÉDUIRE BUDGET (-20%)'
        ELSE '➡️ MAINTENIR'
    END AS recommandation_budget
FROM marketing_campaigns_clean
GROUP BY campaign_type
ORDER BY conversion_moyenne_pct DESC;

-- Audiences à privilégier
SELECT 
    target_audience,
    COUNT(*) AS campagnes_actuelles,
    ROUND(AVG(conversion_rate * 100), 2) AS conversion_moyenne_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS cpa_moyen,
    CASE 
        WHEN AVG(conversion_rate) > 0.08 THEN '🎯 PRIORITÉ MAXIMALE'
        WHEN AVG(conversion_rate) > 0.06 THEN '✅ PRIORITÉ ÉLEVÉE'
        ELSE '➡️ PRIORITÉ STANDARD'
    END AS niveau_priorite
FROM marketing_campaigns_clean
GROUP BY target_audience
ORDER BY conversion_moyenne_pct DESC;

-- ========================================
-- 10. RÉSUMÉ EXÉCUTIF
-- ========================================

SELECT 
    'RÉSUMÉ EXÉCUTIF MARKETING' AS section,
    (SELECT COUNT(*) FROM marketing_campaigns_clean) AS total_campagnes,
    (SELECT SUM(budget) FROM marketing_campaigns_clean) AS budget_total,
    (SELECT campaign_type FROM (
        SELECT campaign_type, AVG(conversion_rate) AS conv 
        FROM marketing_campaigns_clean 
        GROUP BY campaign_type 
        ORDER BY conv DESC 
        LIMIT 1
    )) AS meilleur_type_campagne,
    (SELECT target_audience FROM (
        SELECT target_audience, AVG(conversion_rate) AS conv 
        FROM marketing_campaigns_clean 
        GROUP BY target_audience 
        ORDER BY conv DESC 
        LIMIT 1
    )) AS meilleure_audience,
    (SELECT ROUND(AVG(conversion_rate * 100), 2) FROM marketing_campaigns_clean) AS conversion_moyenne_pct,
    (SELECT ROUND(AVG(cost_per_acquisition), 2) FROM marketing_campaigns_clean WHERE cost_per_acquisition > 0) AS cpa_moyen;