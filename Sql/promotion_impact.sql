-- ========================================
-- ANYCOMPANY - ANALYSE IMPACT DES PROMOTIONS
-- Phase 2.3 : Ventes et Promotions
-- ========================================

USE DATABASE ANYCOMPANY_LAB;
USE SCHEMA SILVER;

-- ========================================
-- 1. VUE D'ENSEMBLE DES PROMOTIONS
-- ========================================

-- Statistiques globales des promotions
SELECT 
    'Vue d ensemble des promotions' AS analyse,
    COUNT(*) AS total_promotions,
    COUNT(DISTINCT product_category) AS categories_promues,
    COUNT(DISTINCT region) AS regions_couvertes,
    COUNT(DISTINCT promotion_type) AS types_promotions,
    ROUND(AVG(discount_percentage * 100), 2) AS remise_moyenne_pct,
    ROUND(MIN(discount_percentage * 100), 2) AS remise_min_pct,
    ROUND(MAX(discount_percentage * 100), 2) AS remise_max_pct,
    ROUND(AVG(promotion_duration_days), 0) AS duree_moyenne_jours,
    MIN(start_date) AS premiere_promo,
    MAX(end_date) AS derniere_promo
FROM promotions_clean;

-- Distribution par catégorie de produit
SELECT 
    product_category,
    COUNT(*) AS nombre_promotions,
    ROUND(AVG(discount_percentage * 100), 2) AS remise_moyenne_pct,
    ROUND(AVG(promotion_duration_days), 0) AS duree_moyenne_jours,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_total_promos
FROM promotions_clean
GROUP BY product_category
ORDER BY nombre_promotions DESC;

-- Distribution par type de promotion
SELECT 
    promotion_type,
    COUNT(*) AS nombre_promotions,
    ROUND(AVG(discount_percentage * 100), 2) AS remise_moyenne_pct,
    COUNT(DISTINCT product_category) AS categories_touchees
FROM promotions_clean
GROUP BY promotion_type
ORDER BY nombre_promotions DESC;

-- ========================================
-- 2. COMPARAISON VENTES AVEC/SANS PROMOTION
-- ========================================

-- Créer une vue temporaire des ventes avec flag promotion
CREATE OR REPLACE TEMPORARY TABLE ventes_avec_flag_promo AS
SELECT 
    t.*,
    CASE 
        WHEN p.promotion_id IS NOT NULL THEN 'Avec Promotion'
        ELSE 'Sans Promotion'
    END AS statut_promotion,
    p.promotion_id,
    p.promotion_type,
    p.discount_percentage
FROM financial_transactions_clean t
LEFT JOIN promotions_clean p
    ON t.region = p.region
    AND t.transaction_date BETWEEN p.start_date AND p.end_date
WHERE t.transaction_type = 'Sale';

-- Comparaison globale
SELECT 
    statut_promotion,
    COUNT(*) AS nombre_ventes,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_transactions,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS pct_ca
FROM ventes_avec_flag_promo
GROUP BY statut_promotion
ORDER BY total_ventes DESC;

-- Calcul du LIFT promotionnel
WITH stats_promo AS (
    SELECT 
        AVG(CASE WHEN statut_promotion = 'Avec Promotion' THEN amount END) AS panier_avec_promo,
        AVG(CASE WHEN statut_promotion = 'Sans Promotion' THEN amount END) AS panier_sans_promo
    FROM ventes_avec_flag_promo
)
SELECT 
    panier_avec_promo,
    panier_sans_promo,
    ROUND((panier_avec_promo - panier_sans_promo) * 100.0 / panier_sans_promo, 2) AS lift_pct
FROM stats_promo;

-- Impact par région
SELECT 
    region,
    statut_promotion,
    COUNT(*) AS nombre_ventes,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM ventes_avec_flag_promo
GROUP BY region, statut_promotion
ORDER BY region, statut_promotion;

-- ========================================
-- 3. EFFICACITÉ PAR NIVEAU DE REMISE
-- ========================================

-- Performance par tranche de remise
SELECT 
    CASE 
        WHEN discount_percentage < 0.10 THEN '0-10%'
        WHEN discount_percentage < 0.15 THEN '10-15%'
        WHEN discount_percentage < 0.20 THEN '15-20%'
        ELSE '20%+'
    END AS tranche_remise,
    COUNT(DISTINCT promotion_id) AS nombre_promotions,
    COUNT(*) AS transactions_pendant_promo,
    SUM(amount) AS total_ventes,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM ventes_avec_flag_promo
WHERE statut_promotion = 'Avec Promotion'
GROUP BY tranche_remise
ORDER BY tranche_remise;

-- ROI par niveau de remise (simplifié)
WITH ventes_par_remise AS (
    SELECT 
        CASE 
            WHEN discount_percentage < 0.10 THEN '0-10%'
            WHEN discount_percentage < 0.15 THEN '10-15%'
            WHEN discount_percentage < 0.20 THEN '15-20%'
            ELSE '20%+'
        END AS tranche_remise,
        SUM(amount) AS ca_total,
        COUNT(*) AS nb_ventes
    FROM ventes_avec_flag_promo
    WHERE statut_promotion = 'Avec Promotion'
    GROUP BY tranche_remise
)
SELECT 
    tranche_remise,
    ca_total,
    nb_ventes,
    ROUND(ca_total / nb_ventes, 2) AS ca_par_vente,
    CASE 
        WHEN tranche_remise = '10-15%' THEN '⭐⭐⭐⭐⭐ OPTIMAL'
        WHEN tranche_remise = '0-10%' THEN '⭐⭐⭐⭐ EXCELLENT'
        WHEN tranche_remise = '15-20%' THEN '⭐⭐⭐ BON'
        ELSE '⭐⭐ MARGINAL'
    END AS evaluation
FROM ventes_par_remise
ORDER BY ca_par_vente DESC;

-- ========================================
-- 4. TOP PROMOTIONS PERFORMANTES
-- ========================================

-- Top 20 promotions par chiffre d'affaires généré
SELECT 
    p.promotion_id,
    p.product_category,
    p.promotion_type,
    p.region,
    ROUND(p.discount_percentage * 100, 2) AS remise_pct,
    p.start_date,
    p.end_date,
    p.promotion_duration_days,
    COUNT(v.transaction_id) AS transactions_pendant_promo,
    SUM(v.amount) AS ca_genere,
    ROUND(AVG(v.amount), 2) AS panier_moyen,
    ROUND(SUM(v.amount) / p.promotion_duration_days, 2) AS ca_par_jour
FROM promotions_clean p
LEFT JOIN ventes_avec_flag_promo v 
    ON v.promotion_id = p.promotion_id
GROUP BY p.promotion_id, p.product_category, p.promotion_type, p.region, 
         p.discount_percentage, p.start_date, p.end_date, p.promotion_duration_days
HAVING COUNT(v.transaction_id) > 0
ORDER BY ca_genere DESC
LIMIT 20;

-- Promotions les moins performantes
SELECT 
    p.promotion_id,
    p.product_category,
    p.promotion_type,
    p.region,
    ROUND(p.discount_percentage * 100, 2) AS remise_pct,
    COUNT(v.transaction_id) AS transactions_pendant_promo,
    COALESCE(SUM(v.amount), 0) AS ca_genere
FROM promotions_clean p
LEFT JOIN ventes_avec_flag_promo v 
    ON v.promotion_id = p.promotion_id
GROUP BY p.promotion_id, p.product_category, p.promotion_type, p.region, p.discount_percentage
ORDER BY ca_genere ASC
LIMIT 10;

-- ========================================
-- 5. ANALYSE PAR CATÉGORIE DE PRODUIT
-- ========================================

-- Lift par catégorie
WITH lift_categorie AS (
    SELECT 
        region,
        AVG(CASE WHEN statut_promotion = 'Sans Promotion' THEN amount END) AS panier_sans_promo,
        AVG(CASE WHEN statut_promotion = 'Avec Promotion' THEN amount END) AS panier_avec_promo,
        COUNT(CASE WHEN statut_promotion = 'Sans Promotion' THEN 1 END) AS ventes_sans_promo,
        COUNT(CASE WHEN statut_promotion = 'Avec Promotion' THEN 1 END) AS ventes_avec_promo
    FROM ventes_avec_flag_promo
    GROUP BY region
)
SELECT 
    region,
    panier_sans_promo,
    panier_avec_promo,
    ventes_sans_promo,
    ventes_avec_promo,
    ROUND((panier_avec_promo - panier_sans_promo) * 100.0 / NULLIF(panier_sans_promo, 0), 2) AS lift_pct,
    CASE 
        WHEN (panier_avec_promo - panier_sans_promo) * 100.0 / NULLIF(panier_sans_promo, 0) > 50 THEN '🔥 TRÈS SENSIBLE'
        WHEN (panier_avec_promo - panier_sans_promo) * 100.0 / NULLIF(panier_sans_promo, 0) > 30 THEN '✅ SENSIBLE'
        WHEN (panier_avec_promo - panier_sans_promo) * 100.0 / NULLIF(panier_sans_promo, 0) > 10 THEN '➡️ MOYENNEMENT SENSIBLE'
        ELSE '⚠️ PEU SENSIBLE'
    END AS sensibilite
FROM lift_categorie
ORDER BY lift_pct DESC;

-- ========================================
-- 6. DURÉE OPTIMALE DES PROMOTIONS
-- ========================================

SELECT 
    CASE 
        WHEN promotion_duration_days <= 7 THEN '1 semaine ou moins'
        WHEN promotion_duration_days <= 14 THEN '1-2 semaines'
        WHEN promotion_duration_days <= 21 THEN '2-3 semaines'
        ELSE 'Plus de 3 semaines'
    END AS categorie_duree,
    COUNT(DISTINCT p.promotion_id) AS nombre_promotions,
    ROUND(AVG(p.discount_percentage * 100), 2) AS remise_moyenne_pct,
    COUNT(v.transaction_id) AS total_transactions,
    SUM(v.amount) AS total_ventes,
    ROUND(SUM(v.amount) / COUNT(DISTINCT p.promotion_id), 2) AS ca_moyen_par_promo
FROM promotions_clean p
LEFT JOIN ventes_avec_flag_promo v ON v.promotion_id = p.promotion_id
GROUP BY categorie_duree
ORDER BY 
    CASE categorie_duree
        WHEN '1 semaine ou moins' THEN 1
        WHEN '1-2 semaines' THEN 2
        WHEN '2-3 semaines' THEN 3
        ELSE 4
    END;

-- ========================================
-- 7. SENSIBILITÉ RÉGIONALE AUX PROMOTIONS
-- ========================================

SELECT 
    region,
    COUNT(DISTINCT CASE WHEN statut_promotion = 'Avec Promotion' THEN promotion_id END) AS promotions_lancees,
    SUM(CASE WHEN statut_promotion = 'Avec Promotion' THEN amount ELSE 0 END) AS ca_avec_promo,
    SUM(CASE WHEN statut_promotion = 'Sans Promotion' THEN amount ELSE 0 END) AS ca_sans_promo,
    ROUND(
        SUM(CASE WHEN statut_promotion = 'Avec Promotion' THEN amount ELSE 0 END) * 100.0 / 
        NULLIF(SUM(amount), 0), 
    2) AS pct_ca_sous_promo,
    ROUND(
        (SUM(CASE WHEN statut_promotion = 'Avec Promotion' THEN amount ELSE 0 END) / 
         NULLIF(SUM(CASE WHEN statut_promotion = 'Sans Promotion' THEN amount ELSE 0 END), 0) - 1) * 100,
    2) AS lift_regional_pct
FROM ventes_avec_flag_promo
GROUP BY region
ORDER BY lift_regional_pct DESC;

-- ========================================
-- 8. RECOMMANDATIONS BASÉES SUR LES DONNÉES
-- ========================================

-- Catégories à promouvoir en priorité
SELECT 
    'CATÉGORIES PRIORITAIRES POUR PROMOTIONS' AS recommandation,
    region,
    COUNT(DISTINCT promotion_id) AS promotions_realisees,
    SUM(amount) AS ca_genere,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM ventes_avec_flag_promo
WHERE statut_promotion = 'Avec Promotion'
GROUP BY region
HAVING COUNT(DISTINCT promotion_id) >= 3
ORDER BY ca_genere DESC
LIMIT 10;

-- Timing optimal pour les promotions (saisonnalité)
SELECT 
    QUARTER(start_date) AS trimestre,
    TO_CHAR(start_date, 'Month') AS mois,
    COUNT(*) AS promotions_lancees,
    ROUND(AVG(v.amount), 2) AS panier_moyen_pendant_promo
FROM promotions_clean p
LEFT JOIN ventes_avec_flag_promo v ON v.promotion_id = p.promotion_id
GROUP BY QUARTER(start_date), TO_CHAR(start_date, 'Month'), MONTH(start_date)
ORDER BY panier_moyen_pendant_promo DESC;

-- Résumé exécutif promotions
SELECT 
    'RÉSUMÉ EXÉCUTIF - PROMOTIONS' AS section,
    (SELECT COUNT(*) FROM promotions_clean) AS total_promotions,
    (SELECT ROUND(AVG(discount_percentage * 100), 2) FROM promotions_clean) AS remise_moyenne_pct,
    (SELECT COUNT(*) FROM ventes_avec_flag_promo WHERE statut_promotion = 'Avec Promotion') AS ventes_sous_promo,
    (SELECT ROUND(AVG(amount), 2) FROM ventes_avec_flag_promo WHERE statut_promotion = 'Avec Promotion') AS panier_moyen_avec_promo,
    (SELECT ROUND(AVG(amount), 2) FROM ventes_avec_flag_promo WHERE statut_promotion = 'Sans Promotion') AS panier_moyen_sans_promo;