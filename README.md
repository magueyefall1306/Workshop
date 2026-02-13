# Worshop# 🏢 AnyCompany Food & Beverage - Marketing Analytics

## 📊 Contexte Business

AnyCompany Food & Beverage fait face à une **crise majeure** :
- 📉 **Baisse des ventes** sans précédent
- 📊 **Part de marché** : 28% → 22% (en 8 mois)
- 💰 **Budget marketing** réduit de 30%
- 🎯 **Objectif** : Atteindre 32% de part de marché d'ici T4 2025

## 🎯 Objectif du Projet

Analyse data-driven complète pour :
1. Inverser la tendance à la baisse des ventes
2. Optimiser l'allocation du budget marketing réduit
3. Identifier les produits et segments à fort potentiel
4. Augmenter la part de marché de 10 points

## 🗂️ Structure du Projet
```
anycompany-marketing-analytics/
│
├── sql/                          
│   ├── Load_data.sql            # Chargement des données depuis S3
│   ├── clean_data.sql           # Nettoyage BRONZE → SILVER
│   ├── sales_trends.sql         # Analyse tendances de ventes
│   ├── promotion_impact.sql     # Impact des promotions
│   └── campaign_performance.sql # Performance des campagnes
│
├── streamlit/                    
│   ├── sales_dashboard.py       # Dashboard ventes
│   ├── promotion_analysis.py    # Analyse promotions
│   └── marketing_roi.py         # ROI marketing
│
├── ml/                          
│   ├── customer_segmentation.ipynb
│   ├── purchase_propensity.ipynb
│   └── promotion_response_model.ipynb
│
├── README.md                    
└── business_insights.md         
```

## 🚀 Utilisation

### Étape 1 : Configuration Snowflake

1. Créer un compte Snowflake (essai gratuit 120 jours pour étudiants)
   - URL : https://signup.snowflake.com/?trial=student
   - Société : **MBAESG**
   - Rôle : **Étudiant**
   - Edition : **Enterprise**
   - Cloud : **AWS**
   - Région : **us-west-2**

2. Se connecter à Snowflake
3. Créer un nouveau Worksheet

### Étape 2 : Charger les Données

Dans Snowflake Worksheet :
```sql
-- Exécuter le fichier complet
@sql/Load_data.sql
```

Attendre ~5 minutes que toutes les données soient chargées.

### Étape 3 : Nettoyer les Données
```sql
-- Exécuter le nettoyage
@sql/clean_data.sql
```

### Étape 4 : Analyses Business

Exécuter les analyses SQL dans l'ordre :

1. `sql/sales_trends.sql` - Tendances de ventes
2. `sql/promotion_impact.sql` - Impact promotions
3. `sql/campaign_performance.sql` - Performance marketing

### Étape 5 : Dashboards Streamlit (Optionnel)
```bash
# Installer les dépendances
pip install streamlit pandas plotly snowflake-connector-python

# Lancer les dashboards
streamlit run streamlit/sales_dashboard.py
streamlit run streamlit/promotion_analysis.py
streamlit run streamlit/marketing_roi.py
```

## 📊 Données Sources

**Localisation** : S3 (s3://logbrain-datalake/datasets/food-beverage/)

**11 fichiers** :
- `customer_demographics.csv` - Données clients
- `financial_transactions.csv` - Transactions de ventes
- `promotions-data.csv` - Promotions
- `marketing_campaigns.csv` - Campagnes marketing
- `product_reviews.csv` - Avis produits
- `inventory.json` - Inventaire
- `store_locations.json` - Magasins
- `logistics_and_shipping.csv` - Logistique
- `supplier_information.csv` - Fournisseurs
- `employee_records.csv` - Employés
- `customer_service_interactions.csv` - Service client

**Période couverte** : 2010-2025

## 📈 Insights Clés

Voir le document [business_insights.md](./business_insights.md) pour :
- ✅ Analyse détaillée des tendances
- ✅ Impact des promotions (Lift +42%)
- ✅ Performance marketing par canal
- ✅ Segmentation clients (4 segments)
- ✅ 10 recommandations prioritaires
- ✅ Roadmap de mise en œuvre

## 🛠️ Technologies Utilisées

- **Data Warehouse** : Snowflake
- **Analyses** : SQL
- **Visualisation** : Streamlit + Plotly
- **Machine Learning** : Python (scikit-learn, pandas)

## 👥 Équipe

- **Data Engineer** : Chargement et nettoyage
- **Data Analyst** : Analyses SQL et insights
- **Business Analyst** : Recommandations stratégiques

## 📧 Contact

Pour toute question : [votre-email]

## 📄 Licence

Projet académique - MBA ESG 2026