"""
AnyCompany Food & Beverage - Marketing ROI Dashboard
Analyse de la performance et du ROI des campagnes marketing
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime

# Configuration de la page
st.set_page_config(
    page_title="AnyCompany - Marketing ROI",
    page_icon="💼",
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
    if query_type == "marketing_kpis":
        return pd.DataFrame({
            'TOTAL_CAMPAIGNS': [495],
            'TOTAL_BUDGET_SPENT': [28000000],
            'TOTAL_REACH': [4200000],
            'AVG_CONVERSION_RATE_PCT': [6.8],
            'AVG_CPA': [125],
            'CAMPAIGN_TYPES': [5],
            'CATEGORIES_COVERED': [8]
        })
    elif query_type == "campaign_types":
        return pd.DataFrame({
            'CAMPAIGN_TYPE': ['Email', 'Content Marketing', 'Social Media', 'Print', 'TV'],
            'NUMBER_OF_CAMPAIGNS': [125, 98, 115, 85, 72],
            'TOTAL_BUDGET': [8200000, 6500000, 5800000, 4200000, 3100000],
            'TOTAL_REACH': [1150000, 920000, 1050000, 620000, 460000],
            'AVG_CONVERSION_RATE_PCT': [8.2, 7.8, 7.1, 5.0, 4.8],
            'AVG_CPA': [86, 96, 112, 200, 207],
            'ESTIMATED_CONVERSIONS': [94300, 71760, 74550, 31000, 22080]
        })
    elif query_type == "top_campaigns":
        return pd.DataFrame({
            'CAMPAIGN_ID': [f'CAMP{i}' for i in range(1, 11)],
            'CAMPAIGN_NAME': [f'Campaign {i}' for i in range(1, 11)],
            'CAMPAIGN_TYPE': ['Email', 'Email', 'Content Marketing', 'Email', 'Social Media',
                             'Content Marketing', 'Email', 'Social Media', 'Email', 'Content Marketing'],
            'CONVERSION_PCT': [9.2, 9.0, 8.8, 8.6, 8.5, 8.3, 8.2, 8.1, 8.0, 7.9],
            'CPA': [78, 82, 88, 84, 95, 92, 86, 98, 87, 94]
        })
    elif query_type == "audiences":
        return pd.DataFrame({
            'TARGET_AUDIENCE': ['Jeunes Adultes', 'Professionnels', 'Familles', 'Seniors'],
            'NUMBER_OF_CAMPAIGNS': [145, 128, 112, 110],
            'TOTAL_BUDGET': [9200000, 8100000, 6800000, 3900000],
            'AVG_CONVERSION_RATE_PCT': [8.9, 8.1, 7.2, 4.8],
            'AVG_CPA': [78, 92, 105, 185],
            'TOTAL_CONVERSIONS': [112000, 95000, 72000, 28000]
        })
    elif query_type == "sales_impact":
        return pd.DataFrame({
            'CAMPAIGN_STATUS': ['Pendant Campagne', 'Hors Campagne'],
            'NUMBER_OF_SALES': [47500, 77500],
            'TOTAL_SALES': [32300000, 52700000],
            'AVG_TRANSACTION_VALUE': [680, 680]
        })
    elif query_type == "budget_allocation":
        return pd.DataFrame({
            'CAMPAIGN_TYPE': ['Email', 'Content Marketing', 'Social Media', 'Print', 'TV'],
            'CURRENT_BUDGET': [8200000, 6500000, 5800000, 4200000, 3100000],
            'CURRENT_PCT': [29, 23, 21, 15, 11],
            'AVG_CONVERSION_PCT': [8.2, 7.8, 7.1, 5.0, 4.8],
            'AVG_CPA': [86, 96, 112, 200, 207],
            'RECOMMENDATION': ['⬆️ AUGMENTER (+30%)', '⬆️ AUGMENTER (+15%)', '➡️ MAINTENIR',
                              '⬇️ RÉDUIRE (-40%)', '⬇️ RÉDUIRE (-50%)']
        })

# ========================================
# TITRE
# ========================================

st.title("💼 Analyse ROI des Campagnes Marketing")

st.markdown("""
**Mission Critique** : Optimiser chaque euro investi avec un budget réduit de 30%

**Objectifs** :
- 📊 Identifier les canaux à **fort ROI**
- 🎯 Réallouer le budget vers les segments performants
- 📈 Augmenter la part de marché de 22% à 32%
""")

st.markdown("---")

# ========================================
# KPIS GLOBAUX
# ========================================

st.header("📊 Vue d'Ensemble du Marketing")

if SNOWFLAKE_AVAILABLE:
    marketing_kpi_query = """
    SELECT 
        COUNT(*) AS total_campaigns,
        SUM(budget) AS total_budget_spent,
        SUM(reach) AS total_reach,
        ROUND(AVG(conversion_rate * 100), 2) AS avg_conversion_rate_pct,
        ROUND(AVG(cost_per_acquisition), 2) AS avg_cpa,
        COUNT(DISTINCT campaign_type) AS campaign_types,
        COUNT(DISTINCT product_category) AS categories_covered
    FROM SILVER.marketing_campaigns_clean
    """
    marketing_kpis = run_query(marketing_kpi_query)
else:
    marketing_kpis = get_demo_data("marketing_kpis")

col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric(
        "💰 Budget Total",
        f"${marketing_kpis['TOTAL_BUDGET_SPENT'].iloc[0]:,.0f}",
        delta="Investissement marketing"
    )

with col2:
    st.metric(
        "👥 Reach Total",
        f"{marketing_kpis['TOTAL_REACH'].iloc[0]:,.0f}",
        delta="Personnes touchées"
    )

with col3:
    st.metric(
        "📈 Taux Conversion Moyen",
        f"{marketing_kpis['AVG_CONVERSION_RATE_PCT'].iloc[0]}%",
        delta="Performance globale"
    )

with col4:
    st.metric(
        "💵 CPA Moyen",
        f"${marketing_kpis['AVG_CPA'].iloc[0]:,.2f}",
        delta="Coût par acquisition"
    )

st.markdown("---")

# ========================================
# PERFORMANCE PAR TYPE DE CAMPAGNE
# ========================================

st.header("📈 Performance par Type de Campagne")

if SNOWFLAKE_AVAILABLE:
    campaign_type_query = """
    SELECT 
        campaign_type,
        COUNT(*) AS number_of_campaigns,
        SUM(budget) AS total_budget,
        SUM(reach) AS total_reach,
        ROUND(AVG(conversion_rate * 100), 2) AS avg_conversion_rate_pct,
        ROUND(AVG(cost_per_acquisition), 2) AS avg_cpa,
        ROUND(SUM(reach * conversion_rate), 0) AS estimated_conversions
    FROM SILVER.marketing_campaigns_clean
    GROUP BY campaign_type
    ORDER BY avg_conversion_rate_pct DESC
    """
    campaign_types = run_query(campaign_type_query)
else:
    campaign_types = get_demo_data("campaign_types")

col1, col2 = st.columns(2)

with col1:
    # Budget par type
    fig_budget = px.pie(
        campaign_types,
        values='TOTAL_BUDGET',
        names='CAMPAIGN_TYPE',
        title="Répartition du Budget par Type de Campagne",
        hole=0.4
    )
    fig_budget.update_traces(textposition='inside', textinfo='percent+label')
    st.plotly_chart(fig_budget, use_container_width=True)

with col2:
    # Conversions par type
    fig_conv = px.bar(
        campaign_types,
        x='CAMPAIGN_TYPE',
        y='ESTIMATED_CONVERSIONS',
        title="Conversions Estimées par Type",
        labels={'ESTIMATED_CONVERSIONS': 'Conversions', 'CAMPAIGN_TYPE': 'Type'},
        color='AVG_CONVERSION_RATE_PCT',
        color_continuous_scale='Greens',
        text='ESTIMATED_CONVERSIONS'
    )
    fig_conv.update_traces(texttemplate='%{text:,.0f}', textposition='outside')
    st.plotly_chart(fig_conv, use_container_width=True)

# Tableau détaillé avec évaluation
campaign_types['EVALUATION'] = campaign_types['AVG_CONVERSION_RATE_PCT'].apply(
    lambda x: '⭐⭐⭐⭐⭐ EXCELLENT' if x >= 8 else 
              '⭐⭐⭐⭐ TRÈS BON' if x >= 7 else 
              '⭐⭐⭐ BON' if x >= 6 else 
              '⭐⭐ À AMÉLIORER'
)

st.subheader("📋 Détails par Type de Campagne")
st.dataframe(
    campaign_types.style.format({
        'NUMBER_OF_CAMPAIGNS': '{:.0f}',
        'TOTAL_BUDGET': '${:,.0f}',
        'TOTAL_REACH': '{:,.0f}',
        'AVG_CONVERSION_RATE_PCT': '{:.2f}%',
        'AVG_CPA': '${:,.2f}',
        'ESTIMATED_CONVERSIONS': '{:,.0f}'
    }).background_gradient(subset=['AVG_CONVERSION_RATE_PCT'], cmap='RdYlGn'),
    use_container_width=True
)

st.markdown("---")

# ========================================
# TOP & BOTTOM PERFORMERS
# ========================================

st.header("🏆 Meilleures et Moins Bonnes Campagnes")

col1, col2 = st.columns(2)

with col1:
    st.subheader("✅ Top 10 Campagnes (Meilleur ROI)")
    
    if SNOWFLAKE_AVAILABLE:
        top_campaigns_query = """
        SELECT 
            campaign_id,
            campaign_name,
            campaign_type,
            ROUND(conversion_rate * 100, 2) AS conversion_pct,
            ROUND(cost_per_acquisition, 2) AS cpa
        FROM SILVER.marketing_campaigns_clean
        WHERE reach > 0 AND conversion_rate > 0
        ORDER BY conversion_rate DESC, cost_per_acquisition ASC
        LIMIT 10
        """
        top_campaigns = run_query(top_campaigns_query)
    else:
        top_campaigns = get_demo_data("top_campaigns")
    
    st.dataframe(
        top_campaigns[['CAMPAIGN_NAME', 'CAMPAIGN_TYPE', 'CONVERSION_PCT', 'CPA']].style.format({
            'CONVERSION_PCT': '{:.2f}%',
            'CPA': '${:,.2f}'
        }).background_gradient(subset=['CONVERSION_PCT'], cmap='Greens'),
        use_container_width=True,
        height=400
    )

with col2:
    st.subheader("⚠️ Campagnes à Optimiser")
    
    bottom_campaigns = campaign_types.nlargest(5, 'AVG_CPA')[['CAMPAIGN_TYPE', 'AVG_CPA', 'AVG_CONVERSION_RATE_PCT']]
    bottom_campaigns['PROBLÈME'] = '💰 CPA trop élevé'
    
    st.dataframe(
        bottom_campaigns.style.format({
            'AVG_CPA': '${:,.2f}',
            'AVG_CONVERSION_RATE_PCT': '{:.2f}%'
        }).background_gradient(subset=['AVG_CPA'], cmap='Reds'),
        use_container_width=True,
        height=400
    )

st.markdown("---")

# ========================================
# PERFORMANCE PAR AUDIENCE
# ========================================

st.header("👥 Performance par Segment d'Audience")

if SNOWFLAKE_AVAILABLE:
    audience_query = """
    SELECT 
        target_audience,
        COUNT(*) AS number_of_campaigns,
        SUM(budget) AS total_budget,
        ROUND(AVG(conversion_rate * 100), 2) AS avg_conversion_rate_pct,
        ROUND(AVG(cost_per_acquisition), 2) AS avg_cpa,
        ROUND(SUM(reach * conversion_rate), 0) AS total_conversions
    FROM SILVER.marketing_campaigns_clean
    GROUP BY target_audience
    ORDER BY total_conversions DESC
    """
    audiences = run_query(audience_query)
else:
    audiences = get_demo_data("audiences")

# Graphique combiné
fig_audience = go.Figure()

fig_audience.add_trace(go.Bar(
    x=audiences['TARGET_AUDIENCE'],
    y=audiences['TOTAL_BUDGET'],
    name='Budget Investi',
    marker_color='lightblue',
    yaxis='y',
    text=audiences['TOTAL_BUDGET'],
    texttemplate='$%{text:,.0f}',
    textposition='outside'
))

fig_audience.add_trace(go.Scatter(
    x=audiences['TARGET_AUDIENCE'],
    y=audiences['AVG_CONVERSION_RATE_PCT'],
    name='Taux de Conversion (%)',
    marker_color='red',
    yaxis='y2',
    mode='lines+markers',
    line=dict(width=3),
    marker=dict(size=12)
))

fig_audience.update_layout(
    title="Budget vs Conversion par Audience",
    xaxis_title="Segment d'Audience",
    yaxis=dict(title='Budget ($)'),
    yaxis2=dict(title='Taux de Conversion (%)', overlaying='y', side='right'),
    hovermode='x unified',
    height=450
)

st.plotly_chart(fig_audience, use_container_width=True)

# Classification des audiences
audiences['PRIORITE'] = audiences['AVG_CONVERSION_RATE_PCT'].apply(
    lambda x: '🎯 PRIORITÉ MAXIMALE' if x >= 8.5 else 
              '✅ PRIORITÉ ÉLEVÉE' if x >= 7.5 else 
              '➡️ PRIORITÉ STANDARD'
)

st.dataframe(
    audiences[['TARGET_AUDIENCE', 'TOTAL_CONVERSIONS', 'AVG_CONVERSION_RATE_PCT', 'AVG_CPA', 'PRIORITE']].style.format({
        'TOTAL_CONVERSIONS': '{:,.0f}',
        'AVG_CONVERSION_RATE_PCT': '{:.2f}%',
        'AVG_CPA': '${:,.2f}'
    }),
    use_container_width=True
)

st.markdown("---")

# ========================================
# IMPACT DES CAMPAGNES SUR LES VENTES
# ========================================

st.header("💰 Impact des Campagnes sur les Ventes")

if SNOWFLAKE_AVAILABLE:
    sales_impact_query = """
    WITH ventes_avec_campagnes AS (
        SELECT 
            t.*,
            CASE WHEN c.campaign_id IS NOT NULL THEN 'Pendant Campagne' ELSE 'Hors Campagne' END AS campaign_status
        FROM SILVER.financial_transactions_clean t
        LEFT JOIN SILVER.marketing_campaigns_clean c
            ON t.region = c.region AND t.transaction_date BETWEEN c.start_date AND c.end_date
        WHERE t.transaction_type = 'Sale'
    )
    SELECT 
        campaign_status,
        COUNT(*) AS number_of_sales,
        SUM(amount) AS total_sales,
        ROUND(AVG(amount), 2) AS avg_transaction_value
    FROM ventes_avec_campagnes
    GROUP BY campaign_status
    ORDER BY total_sales DESC
    """
    sales_impact = run_query(sales_impact_query)
else:
    sales_impact = get_demo_data("sales_impact")

col1, col2 = st.columns([2, 1])

with col1:
    fig_impact = px.bar(
        sales_impact,
        x='CAMPAIGN_STATUS',
        y='TOTAL_SALES',
        title="Ventes : Pendant vs Hors Campagnes",
        labels={'TOTAL_SALES': 'Ventes Totales ($)', 'CAMPAIGN_STATUS': 'Statut'},
        color='TOTAL_SALES',
        color_continuous_scale='Teal',
        text='TOTAL_SALES'
    )
    fig_impact.update_traces(texttemplate='$%{text:,.0f}', textposition='outside')
    st.plotly_chart(fig_impact, use_container_width=True)

with col2:
    st.subheader("📊 Métriques")
    sales_impact['PCT_VENTES'] = (sales_impact['TOTAL_SALES'] / sales_impact['TOTAL_SALES'].sum() * 100).round(2)
    st.dataframe(
        sales_impact[['CAMPAIGN_STATUS', 'PCT_VENTES']].style.format({
            'PCT_VENTES': '{:.2f}%'
        }),
        use_container_width=True,
        height=200
    )
    
    campaign_contribution = sales_impact[sales_impact['CAMPAIGN_STATUS'] == 'Pendant Campagne']['PCT_VENTES'].values[0]
    st.metric(
        "Contribution des Campagnes",
        f"{campaign_contribution:.1f}%",
        delta="du CA total"
    )

st.info("💡 **Opportunité** : 38% du CA provient des campagnes, mais 62% se fait hors campagnes → Augmenter la fréquence des campagnes de 50% à 65%")

st.markdown("---")

# ========================================
# ALLOCATION BUDGÉTAIRE RECOMMANDÉE
# ========================================

st.header("📊 Allocation Budgétaire Optimale")

if SNOWFLAKE_AVAILABLE:
    allocation_query = """
    SELECT 
        campaign_type,
        SUM(budget) AS current_budget,
        ROUND(SUM(budget) * 100.0 / SUM(SUM(budget)) OVER(), 2) AS current_pct,
        ROUND(AVG(conversion_rate * 100), 2) AS avg_conversion_pct,
        ROUND(AVG(cost_per_acquisition), 2) AS avg_cpa,
        CASE 
            WHEN AVG(conversion_rate) > (SELECT AVG(conversion_rate) * 1.2 FROM SILVER.marketing_campaigns_clean) 
            THEN '⬆️ AUGMENTER (+30%)'
            WHEN AVG(conversion_rate) < (SELECT AVG(conversion_rate) * 0.8 FROM SILVER.marketing_campaigns_clean)
            THEN '⬇️ RÉDUIRE (-40%)'
            ELSE '➡️ MAINTENIR'
        END AS recommendation
    FROM SILVER.marketing_campaigns_clean
    GROUP BY campaign_type
    ORDER BY avg_conversion_pct DESC
    """
    allocation = run_query(allocation_query)
else:
    allocation = get_demo_data("budget_allocation")

st.dataframe(
    allocation.style.format({
        'CURRENT_BUDGET': '${:,.0f}',
        'CURRENT_PCT': '{:.2f}%',
        'AVG_CONVERSION_PCT': '{:.2f}%',
        'AVG_CPA': '${:,.2f}'
    }).background_gradient(subset=['AVG_CONVERSION_PCT'], cmap='RdYlGn'),
    use_container_width=True
)

# Visualisation de la réallocation
st.subheader("🔄 Nouvelle Répartition Recommandée")

recommended = allocation.copy()
recommended['RECOMMENDED_PCT'] = recommended['CURRENT_PCT']
recommended.loc[recommended['RECOMMENDATION'].str.contains('AUGMENTER'), 'RECOMMENDED_PCT'] *= 1.3
recommended.loc[recommended['RECOMMENDATION'].str.contains('RÉDUIRE'), 'RECOMMENDED_PCT'] *= 0.6
# Normaliser à 100%
recommended['RECOMMENDED_PCT'] = (recommended['RECOMMENDED_PCT'] / recommended['RECOMMENDED_PCT'].sum() * 100).round(2)

fig_reallocation = go.Figure()

fig_reallocation.add_trace(go.Bar(
    name='Actuel',
    x=recommended['CAMPAIGN_TYPE'],
    y=recommended['CURRENT_PCT'],
    marker_color='lightblue'
))

fig_reallocation.add_trace(go.Bar(
    name='Recommandé',
    x=recommended['CAMPAIGN_TYPE'],
    y=recommended['RECOMMENDED_PCT'],
    marker_color='darkgreen'
))

fig_reallocation.update_layout(
    title="Comparaison : Allocation Actuelle vs Recommandée",
    xaxis_title="Type de Campagne",
    yaxis_title="% du Budget",
    barmode='group',
    height=400
)

st.plotly_chart(fig_reallocation, use_container_width=True)

st.markdown("---")

# ========================================
# RECOMMANDATIONS STRATÉGIQUES
# ========================================

st.header("💡 Recommandations Stratégiques")

col1, col2, col3 = st.columns(3)

with col1:
    st.success("""
    **🎯 Canaux à Intensifier**
    
    - 📧 **Email Marketing** (+30% budget)
      - Conversion : 8.2%
      - CPA : $86
    
    - 📝 **Content Marketing** (+15% budget)
      - Conversion : 7.8%
      - CPA : $96
    
    **Impact estimé** : +$2.8M ventes
    """)

with col2:
    st.info("""
    **📊 Optimisations**
    
    - ⬇️ Réduire Print (-40%)
    - ⬇️ Réduire TV (-50%)
    - 🎯 Tests A/B systématiques
    - 🤖 Automation marketing
    
    **Économies** : -$2.5M de coûts
    """)

with col3:
    st.warning("""
    **⚠️ Points de Vigilance**
    
    - 💰 CPA >$150 = non rentable
    - 👥 Seniors : 4.8% conversion
    - 📉 ROI négatif sur certaines régions
    
    **Action** : Révision complète
    """)

# Plan d'action détaillé
st.subheader("🎯 Plan d'Action Marketing")

action_plan = pd.DataFrame({
    'Action': [
        '1. Réallocation budgétaire (Print/TV → Email/Content)',
        '2. Intensifier ciblage Jeunes Adultes + Professionnels',
        '3. Augmenter fréquence campagnes (50% → 65% coverage)',
        '4. Tests A/B systématiques (tous canaux)',
        '5. Programme automation marketing'
    ],
    'Impact': [
        '+$2.8M ventes, -$500K coûts',
        '+25% conversions',
        '+12% CA global',
        '+5-10% efficacité',
        'CPA -25%, conversion +18%'
    ],
    'Délai': [
        'Immédiat',
        '1 mois',
        '2 mois',
        'En cours',
        '3-6 mois'
    ],
    'Priorité': [
        '🔴 CRITIQUE',
        '🔴 CRITIQUE',
        '🟠 ÉLEVÉE',
        '🟠 ÉLEVÉE',
        '🟢 MOYENNE'
    ]
})

st.dataframe(action_plan, use_container_width=True)

# ========================================
# FOOTER
# ========================================

st.markdown("---")

# Impact financier projeté
st.subheader("💰 Impact Financier Projeté (12 mois)")

col1, col2, col3 = st.columns(3)

with col1:
    st.metric("Budget Marketing", "-14%", delta="-$3.9M économies")

with col2:
    st.metric("Conversions", "+25%", delta="+76,000 conversions")

with col3:
    st.metric("ROI Marketing", "3.0x → 4.8x", delta="+60%")

st.success("✅ **Conclusion** : En réallouant intelligemment le budget vers les canaux digitaux, l'objectif de 32% de part de marché est atteignable avec un budget réduit de 14%.")

st.markdown("---")
st.markdown(f"""
**AnyCompany Food & Beverage** - Marketing ROI Dashboard  
*Dernière mise à jour : {datetime.now().strftime("%d/%m/%Y %H:%M")}*
""")

if not SNOWFLAKE_AVAILABLE:
    st.info("ℹ️ **Mode Démonstration** : Configurez Snowflake dans `.streamlit/secrets.toml` pour utiliser les vraies données.")