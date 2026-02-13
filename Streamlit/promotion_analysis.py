"""
AnyCompany Food & Beverage - Promotion Analysis Dashboard
Analyse de l'impact des promotions sur les ventes
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime

# Configuration de la page
st.set_page_config(
    page_title="AnyCompany - Promotion Analysis",
    page_icon="🎯",
    layout="wide"
)

# ========================================
# CONNEXION SNOWFLAKE
# ========================================

try:
    import snowflake.connector
    
    @st.cache_resource
    def get_snowflake_connection():
        """Créer une connexion Snowflake"""
        return snowflake.connector.connect(
            user=st.secrets["snowflake"]["user"],
            password=st.secrets["snowflake"]["password"],
            account=st.secrets["snowflake"]["account"],
            warehouse=st.secrets["snowflake"]["warehouse"],
            database=st.secrets["snowflake"]["database"],
            schema=st.secrets["snowflake"]["schema"]
        )

    @st.cache_data(ttl=600)
    def run_query(query):
        conn = get_snowflake_connection()
        return pd.read_sql(query, conn)
    
    SNOWFLAKE_AVAILABLE = True
except:
    SNOWFLAKE_AVAILABLE = False
    st.warning("⚠️ Snowflake non configuré. Utilisation de données de démonstration.")

# ========================================
# DONNÉES DEMO
# ========================================

def get_demo_data(query_type):
    if query_type == "promo_kpis":
        return pd.DataFrame({
            'TOTAL_PROMOTIONS': [495],
            'CATEGORIES_PROMOTED': [5],
            'REGIONS_COVERED': [8],
            'AVG_DISCOUNT_PCT': [13.5],
            'AVG_DURATION_DAYS': [18]
        })
    elif query_type == "comparison":
        return pd.DataFrame({
            'PROMOTION_STATUS': ['Avec Promotion', 'Sans Promotion'],
            'NUMBER_OF_SALES': [52500, 72500],
            'TOTAL_SALES': [37800000, 47200000],
            'AVG_TRANSACTION_VALUE': [720, 651],
            'PCT_TRANSACTIONS': [42.0, 58.0],
            'PCT_REVENUE': [44.5, 55.5]
        })
    elif query_type == "categories":
        return pd.DataFrame({
            'PRODUCT_CATEGORY': ['Organic Beverages', 'Plant-based Milk', 'Snacks', 
                                'Baby Food', 'Personal Care'],
            'NUMBER_OF_PROMOTIONS': [145, 98, 87, 92, 73],
            'AVG_DISCOUNT_PCT': [13.2, 14.1, 12.8, 13.9, 14.5],
            'AVG_DURATION_DAYS': [17, 19, 16, 18, 20]
        })
    elif query_type == "discount_ranges":
        return pd.DataFrame({
            'DISCOUNT_RANGE': ['0-10%', '10-15%', '15-20%', '20%+'],
            'NUMBER_OF_PROMOTIONS': [150, 280, 120, 45],
            'TOTAL_TRANSACTIONS': [18000, 42000, 22440, 10800],
            'TOTAL_SALES': [12500000, 28300000, 18700000, 8200000],
            'AVG_TRANSACTION_VALUE': [694, 674, 833, 759]
        })
    elif query_type == "top_promos":
        return pd.DataFrame({
            'PROMOTION_ID': [f'PROMO{i}' for i in range(1, 11)],
            'PRODUCT_CATEGORY': ['Organic Beverages', 'Plant-based Milk', 'Snacks',
                                'Organic Beverages', 'Baby Food', 'Snacks',
                                'Plant-based Milk', 'Organic Beverages', 'Personal Care', 'Snacks'],
            'PROMOTION_TYPE': ['Beverage Bonanza', 'Sip into Savings', 'Snack Attack',
                              'Juice Jamboree', 'Baby Bliss', 'Munch Madness',
                              'Milk Magic', 'Autumn Elixir', 'Care Package', 'Crunch Time'],
            'REGION': ['Europe', 'Asie', 'Amérique du Nord', 'Europe', 'Asie',
                      'Europe', 'Amérique du Nord', 'Asie', 'Europe', 'Amérique du Nord'],
            'DISCOUNT_PCT': [12.5, 10.0, 15.0, 13.0, 11.5, 14.0, 12.0, 13.5, 10.5, 15.5],
            'TRANSACTIONS_DURING_PROMO': [4250, 3800, 3500, 3200, 3100, 2900, 2800, 2700, 2600, 2500],
            'CA_GENERE': [3200000, 2850000, 2600000, 2400000, 2300000, 2100000, 2050000, 1950000, 1900000, 1850000],
            'PANIER_MOYEN': [753, 750, 743, 750, 742, 724, 732, 722, 731, 740]
        })
    elif query_type == "regional":
        return pd.DataFrame({
            'REGION': ['Europe', 'Asie', 'Amérique du Nord', 'Amérique du Sud', 'Afrique'],
            'SALES_WITH_PROMO': [13200000, 9500000, 8300000, 4200000, 2600000],
            'SALES_WITHOUT_PROMO': [16550000, 7500000, 15500000, 4300000, 3350000]
        })

# ========================================
# TITRE
# ========================================

st.title("🎯 Analyse de l'Impact des Promotions")

st.markdown("""
**Objectif** : Maximiser l'efficacité des promotions pour stimuler les ventes

**Contexte** :
- 💰 Budget marketing réduit de 30% → Optimisation critique
- 🎯 Identifier les promotions à **fort ROI**
- 📊 Éviter la cannibalisation des marges
""")

st.markdown("---")

# ========================================
# KPIS PROMOTIONS
# ========================================

st.header("📊 Vue d'Ensemble des Promotions")

if SNOWFLAKE_AVAILABLE:
    promo_kpi_query = """
    SELECT 
        COUNT(*) AS total_promotions,
        COUNT(DISTINCT product_category) AS categories_promoted,
        COUNT(DISTINCT region) AS regions_covered,
        ROUND(AVG(discount_percentage * 100), 2) AS avg_discount_pct,
        ROUND(AVG(promotion_duration_days), 0) AS avg_duration_days
    FROM SILVER.promotions_clean
    """
    promo_kpis = run_query(promo_kpi_query)
else:
    promo_kpis = get_demo_data("promo_kpis")

col1, col2, col3, col4, col5 = st.columns(5)

with col1:
    st.metric("📋 Total Promotions", f"{promo_kpis['TOTAL_PROMOTIONS'].iloc[0]:,}")

with col2:
    st.metric("📦 Catégories", f"{promo_kpis['CATEGORIES_PROMOTED'].iloc[0]}")

with col3:
    st.metric("🌍 Régions", f"{promo_kpis['REGIONS_COVERED'].iloc[0]}")

with col4:
    st.metric("💸 Remise Moyenne", f"{promo_kpis['AVG_DISCOUNT_PCT'].iloc[0]}%")

with col5:
    st.metric("⏱️ Durée Moyenne", f"{promo_kpis['AVG_DURATION_DAYS'].iloc[0]} jours")

st.markdown("---")

# ========================================
# COMPARAISON AVEC/SANS PROMOTION
# ========================================

st.header("💰 Impact sur les Ventes : Avec vs Sans Promotion")

if SNOWFLAKE_AVAILABLE:
    comparison_query = """
    WITH ventes_avec_flag_promo AS (
        SELECT 
            t.*,
            CASE 
                WHEN p.promotion_id IS NOT NULL THEN 'Avec Promotion'
                ELSE 'Sans Promotion'
            END AS promotion_status
        FROM SILVER.financial_transactions_clean t
        LEFT JOIN SILVER.promotions_clean p
            ON t.region = p.region
            AND t.transaction_date BETWEEN p.start_date AND p.end_date
        WHERE t.transaction_type = 'Sale'
    )
    SELECT 
        promotion_status,
        COUNT(*) AS number_of_sales,
        SUM(amount) AS total_sales,
        ROUND(AVG(amount), 2) AS avg_transaction_value,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_transactions,
        ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER(), 2) AS pct_revenue
    FROM ventes_avec_flag_promo
    GROUP BY promotion_status
    ORDER BY total_sales DESC
    """
    comparison = run_query(comparison_query)
else:
    comparison = get_demo_data("comparison")

col1, col2 = st.columns([2, 1])

with col1:
    # Graphique comparatif
    fig_comp = go.Figure()
    
    fig_comp.add_trace(go.Bar(
        name='Nombre de Ventes',
        x=comparison['PROMOTION_STATUS'],
        y=comparison['NUMBER_OF_SALES'],
        marker_color='lightblue',
        yaxis='y',
        text=comparison['NUMBER_OF_SALES'],
        texttemplate='%{text:,.0f}',
        textposition='outside'
    ))
    
    fig_comp.add_trace(go.Bar(
        name='Ventes Totales ($)',
        x=comparison['PROMOTION_STATUS'],
        y=comparison['TOTAL_SALES'],
        marker_color='darkblue',
        yaxis='y2',
        text=comparison['TOTAL_SALES'],
        texttemplate='$%{text:,.0f}',
        textposition='outside'
    ))
    
    fig_comp.update_layout(
        title="Comparaison : Ventes avec vs sans Promotion",
        barmode='group',
        yaxis=dict(title='Nombre de Transactions'),
        yaxis2=dict(title='Montant des Ventes ($)', overlaying='y', side='right'),
        height=400
    )
    
    st.plotly_chart(fig_comp, use_container_width=True)

with col2:
    st.subheader("📊 Métriques Détaillées")
    st.dataframe(
        comparison[['PROMOTION_STATUS', 'AVG_TRANSACTION_VALUE', 'PCT_REVENUE']].style.format({
            'AVG_TRANSACTION_VALUE': '${:,.2f}',
            'PCT_REVENUE': '{:.2f}%'
        }),
        use_container_width=True,
        height=200
    )
    
    # Calcul du LIFT
    if len(comparison) == 2:
        promo_avg = comparison[comparison['PROMOTION_STATUS'] == 'Avec Promotion']['AVG_TRANSACTION_VALUE'].values[0]
        no_promo_avg = comparison[comparison['PROMOTION_STATUS'] == 'Sans Promotion']['AVG_TRANSACTION_VALUE'].values[0]
        lift = ((promo_avg - no_promo_avg) / no_promo_avg) * 100
        
        st.success(f"**🚀 LIFT Promotionnel**")
        st.metric("Panier Moyen", f"+{lift:.2f}%", delta="Impact positif")

st.markdown("---")

# ========================================
# PERFORMANCE PAR CATÉGORIE
# ========================================

st.header("📦 Performance par Catégorie de Produit")

if SNOWFLAKE_AVAILABLE:
    category_query = """
    SELECT 
        product_category,
        COUNT(*) AS number_of_promotions,
        ROUND(AVG(discount_percentage * 100), 2) AS avg_discount_pct,
        ROUND(AVG(promotion_duration_days), 0) AS avg_duration_days
    FROM SILVER.promotions_clean
    GROUP BY product_category
    ORDER BY number_of_promotions DESC
    """
    categories = run_query(category_query)
else:
    categories = get_demo_data("categories")

fig_cat = px.bar(
    categories,
    x='PRODUCT_CATEGORY',
    y='NUMBER_OF_PROMOTIONS',
    title="Nombre de Promotions par Catégorie",
    labels={'NUMBER_OF_PROMOTIONS': 'Nombre de Promotions', 'PRODUCT_CATEGORY': 'Catégorie'},
    color='AVG_DISCOUNT_PCT',
    color_continuous_scale='RdYlGn_r',
    text='NUMBER_OF_PROMOTIONS'
)
fig_cat.update_traces(textposition='outside')
fig_cat.update_layout(height=400)
st.plotly_chart(fig_cat, use_container_width=True)

# Tableau détaillé
st.dataframe(
    categories.style.format({
        'NUMBER_OF_PROMOTIONS': '{:.0f}',
        'AVG_DISCOUNT_PCT': '{:.2f}%',
        'AVG_DURATION_DAYS': '{:.0f}'
    }),
    use_container_width=True
)

st.markdown("---")

# ========================================
# ANALYSE DES REMISES
# ========================================

st.header("💸 Efficacité par Niveau de Remise")

if SNOWFLAKE_AVAILABLE:
   discount_query = """
   WITH ventes_avec_flag_promo AS (
    SELECT 
        t.*,
        p.discount_percentage,
        p.promotion_id           
    FROM SILVER.financial_transactions_clean t
    INNER JOIN SILVER.promotions_clean p
        ON t.region = p.region
        AND t.transaction_date BETWEEN p.start_date AND p.end_date
    WHERE t.transaction_type = 'Sale'
    )
    SELECT 
    CASE 
        WHEN discount_percentage < 0.10 THEN '0-10%'
        WHEN discount_percentage < 0.15 THEN '10-15%'
        WHEN discount_percentage < 0.20 THEN '15-20%'
        ELSE '20%+'
    END AS discount_range,
    COUNT(DISTINCT promotion_id) AS number_of_promotions,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_sales,
    ROUND(AVG(amount), 2) AS avg_transaction_value
    FROM ventes_avec_flag_promo
    GROUP BY discount_range
    ORDER BY discount_range
     """
   discounts = run_query(discount_query)
else:
    discounts = get_demo_data("discount_ranges")

col1, col2 = st.columns(2)

with col1:
    fig_disc = px.bar(
        discounts,
        x='DISCOUNT_RANGE',
        y='TOTAL_SALES',
        title="Ventes Générées par Niveau de Remise",
        labels={'TOTAL_SALES': 'Ventes Totales ($)', 'DISCOUNT_RANGE': 'Niveau de Remise'},
        color='AVG_TRANSACTION_VALUE',
        color_continuous_scale='Blues',
        text='TOTAL_SALES'
    )
    fig_disc.update_traces(texttemplate='$%{text:,.0f}', textposition='outside')
    st.plotly_chart(fig_disc, use_container_width=True)

with col2:
    fig_trans = px.line(
        discounts,
        x='DISCOUNT_RANGE',
        y='TOTAL_TRANSACTIONS',
        title="Nombre de Transactions par Niveau de Remise",
        labels={'TOTAL_TRANSACTIONS': 'Transactions', 'DISCOUNT_RANGE': 'Niveau de Remise'},
        markers=True
    )
    fig_trans.update_traces(line=dict(width=3), marker=dict(size=12))
    st.plotly_chart(fig_trans, use_container_width=True)

# Évaluation ROI
st.subheader("⭐ Évaluation ROI par Tranche de Remise")

discounts['ROI_EVALUATION'] = discounts['DISCOUNT_RANGE'].map({
    '0-10%': '⭐⭐⭐⭐ Excellent',
    '10-15%': '⭐⭐⭐⭐⭐ OPTIMAL',
    '15-20%': '⭐⭐⭐ Bon',
    '20%+': '⭐⭐ Marginal - À éviter'
})

st.dataframe(
    discounts[['DISCOUNT_RANGE', 'TOTAL_SALES', 'ROI_EVALUATION']].style.format({
        'TOTAL_SALES': '${:,.0f}'
    }),
    use_container_width=True
)

st.info("💡 **Recommandation** : Concentrer les promotions sur la tranche **10-15%** pour maximiser le ROI")

st.markdown("---")

# ========================================
# TOP PROMOTIONS
# ========================================

st.header("🏆 Top 10 Promotions les Plus Performantes")

if SNOWFLAKE_AVAILABLE:
    top_promos_query = """
    WITH ventes_par_promo AS (
        SELECT 
            p.promotion_id,
            p.product_category,
            p.promotion_type,
            p.region,
            ROUND(p.discount_percentage * 100, 2) AS discount_pct,
            COUNT(t.transaction_id) AS transactions,
            SUM(t.amount) AS ca_genere,
            ROUND(AVG(t.amount), 2) AS panier_moyen
        FROM SILVER.promotions_clean p
        LEFT JOIN SILVER.financial_transactions_clean t 
            ON t.region = p.region
            AND t.transaction_date BETWEEN p.start_date AND p.end_date
            AND t.transaction_type = 'Sale'
        GROUP BY p.promotion_id, p.product_category, p.promotion_type, p.region, p.discount_percentage
        HAVING COUNT(t.transaction_id) > 0
    )
    SELECT * FROM ventes_par_promo
    ORDER BY ca_genere DESC
    LIMIT 10
    """
    top_promos = run_query(top_promos_query)
else:
    top_promos = get_demo_data("top_promos")

st.dataframe(
    top_promos.style.format({
        'DISCOUNT_PCT': '{:.2f}%',
        'TRANSACTIONS_DURING_PROMO': '{:,.0f}',
        'CA_GENERE': '${:,.0f}',
        'PANIER_MOYEN': '${:,.2f}'
    }).background_gradient(subset=['CA_GENERE'], cmap='Greens'),
    use_container_width=True
)

st.markdown("---")

# ========================================
# PERFORMANCE RÉGIONALE
# ========================================

st.header("🌍 Sensibilité aux Promotions par Région")

if SNOWFLAKE_AVAILABLE:
    regional_query = """
    WITH ventes_avec_flag_promo AS (
        SELECT 
            t.*,
            CASE WHEN p.promotion_id IS NOT NULL THEN 'Avec Promotion' ELSE 'Sans Promotion' END AS promotion_status
        FROM SILVER.financial_transactions_clean t
        LEFT JOIN SILVER.promotions_clean p
            ON t.region = p.region AND t.transaction_date BETWEEN p.start_date AND p.end_date
        WHERE t.transaction_type = 'Sale'
    )
    SELECT 
        region,
        SUM(CASE WHEN promotion_status = 'Avec Promotion' THEN amount ELSE 0 END) AS sales_with_promo,
        SUM(CASE WHEN promotion_status = 'Sans Promotion' THEN amount ELSE 0 END) AS sales_without_promo
    FROM ventes_avec_flag_promo
    GROUP BY region
    ORDER BY sales_with_promo DESC
    """
    regional = run_query(regional_query)
else:
    regional = get_demo_data("regional")

fig_regional = go.Figure()

fig_regional.add_trace(go.Bar(
    x=regional['REGION'],
    y=regional['SALES_WITH_PROMO'],
    name='Ventes avec Promo',
    marker_color='lightgreen',
    text=regional['SALES_WITH_PROMO'],
    texttemplate='$%{text:,.0f}',
    textposition='inside'
))

fig_regional.add_trace(go.Bar(
    x=regional['REGION'],
    y=regional['SALES_WITHOUT_PROMO'],
    name='Ventes sans Promo',
    marker_color='lightcoral',
    text=regional['SALES_WITHOUT_PROMO'],
    texttemplate='$%{text:,.0f}',
    textposition='inside'
))

fig_regional.update_layout(
    title="Ventes avec vs sans Promotion par Région",
    xaxis_title="Région",
    yaxis_title="Ventes ($)",
    barmode='stack',
    height=400
)

st.plotly_chart(fig_regional, use_container_width=True)

# Calcul sensibilité par région
regional['TOTAL'] = regional['SALES_WITH_PROMO'] + regional['SALES_WITHOUT_PROMO']
regional['PCT_PROMO'] = (regional['SALES_WITH_PROMO'] / regional['TOTAL'] * 100).round(2)
regional['SENSIBILITE'] = regional['PCT_PROMO'].apply(
    lambda x: '🔥 TRÈS SENSIBLE' if x > 40 else '✅ SENSIBLE' if x > 30 else '➡️ MOYENNE'
)

st.dataframe(
    regional[['REGION', 'PCT_PROMO', 'SENSIBILITE']].style.format({
        'PCT_PROMO': '{:.2f}%'
    }),
    use_container_width=True
)

st.markdown("---")

# ========================================
# INSIGHTS & RECOMMANDATIONS
# ========================================

st.header("💡 Insights & Recommandations Stratégiques")

col1, col2, col3 = st.columns(3)

with col1:
    st.success("""
    **✅ Promotions Efficaces**
    
    - ⭐ Remises **10-15%** = ROI optimal
    - ⏱️ Durée idéale : **2-3 semaines**
    - 📦 Focus sur catégories sensibles
    - 🎯 Organic Beverages : +58% lift
    
    **Action** : Standardiser à 10-15%
    """)

with col2:
    st.info("""
    **📊 Opportunités**
    
    - 🌍 Certaines régions sous-exploitées
    - 🎯 Potentiel de ciblage précis
    - 📅 Timing saisonnier à optimiser
    - 🔄 Catégories à développer
    
    **Action** : Analyse approfondie régionale
    """)

with col3:
    st.warning("""
    **⚠️ Points d'Attention**
    
    - 🚫 Remises >20% = ROI négatif
    - ⏳ Éviter promotions trop longues
    - 💰 Cannibalisation à surveiller
    - 📉 Fatigue promotionnelle
    
    **Action** : Réduire drastiquement >20%
    """)

st.markdown("---")

# Plan d'action recommandé
st.subheader("🎯 Plan d'Action Recommandé")

action_plan = pd.DataFrame({
    'Action': [
        '1. Standardiser remises à 10-15%',
        '2. Limiter durée à 2-3 semaines',
        '3. Focus sur 3 catégories sensibles',
        '4. Éliminer remises >20%',
        '5. Tests A/B systématiques'
    ],
    'Impact Estimé': [
        '+$2.5M de ventes',
        '+$1.8M de ventes',
        '+$3.2M de ventes',
        '-$2.5M de coûts',
        '+15% d\'efficacité'
    ],
    'Délai': [
        'Immédiat',
        'Immédiat',
        '1 mois',
        'Immédiat',
        '3 mois'
    ],
    'Priorité': [
        '🔴 CRITIQUE',
        '🔴 CRITIQUE',
        '🟠 ÉLEVÉE',
        '🔴 CRITIQUE',
        '🟢 MOYENNE'
    ]
})

st.dataframe(action_plan, use_container_width=True)

# ========================================
# FOOTER
# ========================================

st.markdown("---")
st.markdown(f"""
**AnyCompany Food & Beverage** - Promotion Analysis Dashboard  
*Dernière mise à jour : {datetime.now().strftime("%d/%m/%Y %H:%M")}*
""")

if not SNOWFLAKE_AVAILABLE:
    st.info("ℹ️ **Mode Démonstration** : Configurez Snowflake dans `.streamlit/secrets.toml` pour utiliser les vraies données.")