# AnyCompany Food & Beverage - Data-Driven marketing analytics

**Cours** : Architecture Big Data - MBA ESG 2026

## Contexte du Projet

AnyCompany Food & Beverage fait face à une baisse de ventes sans précédent et une perte de part de marché (de 28% à 22% en 8 mois). Ce projet vise à exploiter les données existantes pour inverser cette tendance et atteindre une part de marché de 32% d'ici T4 2025.

**Objectifs principaux :**
- Inverser la tendance à la baisse des ventes
- Augmenter la part de marché de 10 points (22% → 32%)
- Opérer avec un budget marketing réduit de 30%


## Architecture du projet

### Stack technique
- **Plateforme analytique** : Snowflake (AWS us-west-2)
- **Source de données** : Amazon S3 (`s3://logbrain-datalake/datasets/food-beverage/`)
- **Langage** : SQL (Snowflake)
- **Architecture** : Médaillons (Bronze → Silver → Analytics)

### Architecture médaillons

```
┌─────────────┐      ┌─────────────┐      ┌──────────────┐
│   BRONZE    │ ───> │   SILVER    │ ───> │  ANALYTICS   │
│ (Raw Data)  │      │  (Cleaned)  │      │ (Data Product)│
│  11 tables  │      │  11 tables  │      │   5 tables   │
└─────────────┘      └─────────────┘      └──────────────┘
```

---

## Structure du projet

```
anycompany-marketing-analytics/
├── Data-Driven Marketing Analytics.sql   # Fichier SQL principal (tout-en-un)
├── README.md                              # Ce fichier
└── business_insights.md                   # Insights et recommandations

Structure du fichier SQL principal :
├── PHASE 1 - ÉTAPE 1 : Configuration environnement
├── PHASE 1 - ÉTAPE 2 : Création tables BRONZE (11 tables)
├── PHASE 1 - ÉTAPE 3 : Chargement données S3
├── PHASE 1 - ÉTAPE 4 : Vérifications qualité
├── PHASE 1 - ÉTAPE 5 : Nettoyage → tables SILVER (11 tables)
├── PHASE 3 : Création Data Product ANALYTICS (5 tables)
├── PHASE 2 - ANALYSE 1 : Tendances des ventes
├── PHASE 2 - ANALYSE 2 : Impact des promotions
├── PHASE 2 - ANALYSE 3 : Performance marketing
├── PHASE 2 - ANALYSE 4 : Expérience client
└── PHASE 2 - ANALYSE 5 : Opérations et logistique
```


## Guide d'exécution rapide

### Prérequis
- Compte Snowflake actif
- Accès à : `https://app.snowflake.com/mwycfsc/ykb13542/`

### Étape 1 : connexion Snowflake

1. Ouvrir Snowflake : https://app.snowflake.com/mwycfsc/ykb13542/
2. Se connecter avec vos identifiants
3. Créer un nouveau worksheet

### Étape 2 : exécution du script principal

**Option A : tout exécuter d'un coup**
```sql
-- Copier-coller le contenu du fichier
-- "Data-Driven Marketing Analytics.sql"
-- puis cliquer sur "Run All" (ou Ctrl+Shift+Enter)
```

**Option B : Exécution étape par étape** (recommandé pour compréhension)

```sql
-- 1. Exécuter PHASE 1 - ÉTAPE 1
-- (Configuration : DB, schémas, stages)
-- Temps : ~30 secondes

-- 2. Exécuter PHASE 1 - ÉTAPE 2
-- (Création 11 tables BRONZE)
-- Temps : ~1 minute

-- 3. Exécuter PHASE 1 - ÉTAPE 3
-- (Chargement données S3)
-- Temps : 2-5 minutes

-- 4. Exécuter PHASE 1 - ÉTAPE 4
-- (Vérifications qualité)
-- Temps : ~1 minute

-- 5. Exécuter PHASE 1 - ÉTAPE 5
-- (Nettoyage → 11 tables SILVER)
-- Temps : 3-5 minutes

-- 6. Exécuter PHASE 3
-- (Création 5 tables ANALYTICS)
-- Temps : 2-3 minutes

-- 7. Exécuter ANALYSES (Phase 2)
-- (Au choix selon besoins)
-- Temps : ~30 sec par analyse
```

**Temps total estimé : 10-20 minutes**

### Étape 3 : vérification

```sql
-- Vérifier la structure complète
SELECT 'BRONZE' AS layer, COUNT(*) AS table_count 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'BRONZE' AND TABLE_CATALOG = 'ANYCOMPANY_LAB'
UNION ALL
SELECT 'SILVER', COUNT(*) 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'SILVER' AND TABLE_CATALOG = 'ANYCOMPANY_LAB'
UNION ALL
SELECT 'ANALYTICS', COUNT(*) 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'ANALYTICS' AND TABLE_CATALOG = 'ANYCOMPANY_LAB';

-- Résultat attendu :
-- BRONZE    : 11 tables
-- SILVER    : 11 tables
-- ANALYTICS : 5 tables
```


## Sources de données

### Fichiers CSV (9 fichiers)
| Fichier | Description | Contenu |
|---------|-------------|---------|
| `customer_demographics.csv` | Démographie clients | ID, nom, âge, région, revenu |
| `customer_service_interactions.csv` | Service client | Interactions, durée, satisfaction |
| `financial_transactions.csv` | Transactions | Ventes, montants, méthodes paiement |
| `promotions-data.csv` | Promotions | Type, remise, période, région |
| `marketing_campaigns.csv` | Campagnes marketing | Budget, reach, conversion |
| `product_reviews.csv` | Avis produits | Ratings, commentaires, dates |
| `logistics_and_shipping.csv` | Logistique | Expéditions, délais, coûts |
| `supplier_information.csv` | Fournisseurs | Lead time, fiabilité, qualité |
| `employee_records.csv` | Employés | Département, salaire, ancienneté |

### Fichiers JSON (2 fichiers)
| Fichier | Description | Contenu |
|---------|-------------|---------|
| `inventory.json` | Stocks | Niveaux, points de commande, entrepôts |
| `store_locations.json` | Magasins | Adresses, surface, effectifs |

**Total : 11 sources de données**


## Livrables du projet

### Phase 1 : Data Preparation & Ingestion

**Infrastructure créée :**
- 1 Database : `ANYCOMPANY_LAB`
- 3 Schémas : `BRONZE`, `SILVER`, `ANALYTICS`
- 2 File Formats : CSV, JSON
- 1 Stage S3 : Connexion au bucket
- 1 Warehouse : `ANYCOMPANY_WH` (X-SMALL, auto-suspend 60s)

**Tables BRONZE (11 tables - données brutes) :**
1. customer_demographics
2. customer_service_interactions
3. financial_transactions
4. promotions_data
5. marketing_campaigns
6. product_reviews
7. logistics_and_shipping
8. supplier_information
9. employee_records
10. inventory
11. store_locations

**Tables SILVER (11 tables - données nettoyées) :**
1. customer_demographics_clean
2. customer_service_interactions_clean
3. financial_transactions_clean
4. promotions_clean
5. marketing_campaigns_clean
6. product_reviews_clean
7. logistics_and_shipping_clean
8. supplier_information_clean
9. employee_records_clean
10. inventory_clean
11. store_locations_clean

**Nettoyages appliqués :**
- Suppression valeurs NULL critiques
- Normalisation formats (TRIM, UPPER)
- Correction anomalies (montants négatifs, dates incohérentes)
- Ajout colonnes calculées (durées, statuts, âges)
- Gestion valeurs manquantes (COALESCE)

### Phase 3 : Data Product

**Tables ANALYTICS (5 tables - data products) :**

1. **sales_analytics**
   - Ventes enrichies avec promotions et campagnes
   - Indicateurs temporels (année, trimestre, mois, jour)
   - Séquences de transactions par entit

2. **customer_360**
   - Vue complète clients (démographie + comportement)
   - Segmentation RFM (Recency, Frequency, Monetary)
   - Métriques engagement (avis, achats, satisfaction)

3. **product_performance**
   - Performance produits (avis + inventaire)
   - Catégorisation ratings et stocks
   - Métriques qualité et disponibilité

4. **promotion_effectiveness**
   - Efficacité promotions par catégorie/région
   - Reviews pendant période promo
   - Ratings moyens sous promotion

5. **marketing_roi**
   - ROI campagnes marketing
   - Coût par conversion
   - Score ROI calculé

### Phase 2 : Analyses Business (5 analyses)

**Analyse 1 : Tendances des ventes**
- Évolution temporelle (mensuelle, trimestrielle, annuelle)
- Performance par région
- Types de transactions
- Périodes de pointe (jours, mois)
- Taux de croissance
- Top 20 entités performantes

**Analyse 2 : Impact des promotions**
- Vue d'ensemble promotions (remises, durées)
- Performance par catégorie et région
- Types de promotions
- Calendrier promotionnel
- Top promotions par remise
- Analyse temporelle

**Analyse 3 : Performance marketing**
- ROI par type de campagne
- Performance par région
- Efficacité par audience cible
- Top/Bottom 20 campagnes
- Analyse temporelle
- Durée vs efficacité
- Efficience budgétaire
- Recommandations stratégiques

**Analyse 4 : Expérience client**
- Statistiques avis produits (ratings, satisfaction)
- Service client (résolution, durée, satisfaction)
- Performance par type d'interaction
- Catégories de problèmes
- Tendances temporelles

**Analyse 5 : Opérations & Logistique**
- Analyse stocks (niveaux, ruptures)
- Statut par catégorie et région
- Produits critiques (réapprovisionnement)
- Délais de livraison
- Performance transporteurs
- Analyse retours
- Performance fournisseurs
- Corrélation stock vs délais


## Insights business clés

Consulter **business_insights.md** pour l'analyse complète

### Synthèse Exécutive

#### Problèmes identifiés

| Domaine | Problème | Impact |
|---------|----------|--------|
| **Ventes** | Baisse sur plusieurs régions | Part de marché : 28% → 22% |
| **Marketing** | 30-40% budget gaspillé | ROI sous-optimal |
| **Stocks** | 15-20% produits en rupture | Perte ventes |
| **Satisfaction** | Score moyen 3.8/5 | Risque attrition |

#### Opportunités

| Opportunité | Impact Potentiel | Horizon |
|-------------|------------------|---------|
| Optimisation marketing | +20% efficacité | 3 mois |
| Promotions ciblées | +15% volume catégories sensibles | 3 mois |
| Réappro produits critiques | -50% ruptures | 1 mois |
| Amélioration satisfaction | +15% ventes (+0.5 étoiles) | 6 mois |

**Potentiel global : +35-52% revenus via optimisation data-driven**

#### Top 3 Actions Prioritaires

1. **URGENT : Réallocation budget marketing**
   - Stopper bottom 30% campagnes
   - Doubler budget top 20%
   - Impact : +20% efficacité marketing

2. **URGENT : Promotions ciblées**
   - Focus Organic Beverages (catégorie sensible)
   - Arrêt promotions Electronics (ROI négatif)
   - Impact : +10% marge, +15% volume

3. **Court terme : Réappro critique**
   - Commande urgente top 50 produits
   - Impact : -50% ruptures de stock


## Métriques de succès

### KPIs à suivre

| Catégorie | Métrique | Objectif | Actuel |
|-----------|----------|----------|--------|
| **Croissance** | Part de marché | 32% | 22% |
| **Marketing** | ROI campagnes | > 3:1 | Variable |
| **Opérations** | Taux de rupture | < 5% | 15-20% |
| **Client** | Satisfaction | > 4.2/5 | 3.8/5 |

---

## Exemples derequêtes utiles

### Voir toutes les tables créées

```sql
-- Tables BRONZE
SHOW TABLES IN ANYCOMPANY_LAB.BRONZE;

-- Tables SILVER
SHOW TABLES IN ANYCOMPANY_LAB.SILVER;

-- Tables ANALYTICS
SHOW TABLES IN ANYCOMPANY_LAB.ANALYTICS;
```

### Top 10 produits les mieux notés

```sql
SELECT 
    product_id,
    product_category,
    COUNT(*) AS review_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM ANYCOMPANY_LAB.SILVER.product_reviews_clean
GROUP BY product_id, product_category
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC
LIMIT 10;
```

### Ventes mensuelles avec croissance

```sql
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) AS month,
        SUM(amount) AS revenue
    FROM ANYCOMPANY_LAB.SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY 1
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 / 
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS growth_pct
FROM monthly_sales
ORDER BY month DESC;
```

### Segmentation clients RFM

```sql
SELECT 
    customer_status,
    frequency_segment,
    value_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_lifetime_value
FROM ANYCOMPANY_LAB.ANALYTICS.customer_360
GROUP BY customer_status, frequency_segment, value_segment
ORDER BY customer_count DESC;
```


## Notes importantes

### Gestion des crédits Snowflake

```sql
-- Suspendre le warehouse après usage
ALTER WAREHOUSE ANYCOMPANY_WH SUSPEND;

-- Vérifier le statut
SHOW WAREHOUSES;

-- Réactiver si nécessaire
ALTER WAREHOUSE ANYCOMPANY_WH RESUME;
```

**Configuration auto-suspend :**
- Auto-suspend : 60 secondes
- Warehouse size : X-SMALL
- Toujours suspendre manuellement après une longue session

### Troubleshooting

| Problème | Solution |
|----------|----------|
| "Object does not exist" | Vérifier ordre d'exécution des scripts |
| "Stage S3_STAGE does not exist" | Réexécuter PHASE 1 - ÉTAPE 1 |
| Timeout chargement S3 | Patienter 2-5 min, vérifier connexion internet |
| Crédits épuisés | Vérifier Account > Usage, activer auto-suspend |



## Checklist Finale


- [ ] Fichier SQL principal exécuté sans erreur
- [ ] 27 tables créées au total (11 BRONZE + 11 SILVER + 5 ANALYTICS)
- [ ] Au moins 1 analyse business complétée
- [ ] README.md complété avec informations personnelles
- [ ] business_insights.md lu et compris
- [ ] Projet pushé sur GitHub
- [ ] Accès Snowflake partagés dans l'email


## Resources

**Documentation Snowflake :**
- [SQL Reference](https://docs.snowflake.com/en/sql-reference-commands.html)
- [Loading from S3](https://docs.snowflake.com/en/user-guide/data-load-s3.html)
- [Best Practices](https://docs.snowflake.com/en/user-guide/ui-snowsight-best-practices.html)

**Support :**
- Créer une issue GitHub
- Contacter l'équipe enseignante


## Changelog

**v1.0 - 09 Février 2026**
- Phase 1 : Data Preparation (100%)
- Phase 2 : 5 Analyses Business (100%)
- Phase 3 : Data Product ANALYTICS (100%)
- Documentation complète
- Fichier SQL tout-en-un


**Contenu à envoyer** :
1. Lien GitHub du projet
2. Accès Snowflake :
   - https://app.snowflake.com/mwycfsc/ykb13542/#/workspaces/ws/USER%24/PUBLIC/DEFAULT%24/Data-Driven%20Marketing%20Analytics.sql
   - THANDIE
   - t_dranecophy@stu-mba-esg.com
   - MyCodexCodeESGstu357$
