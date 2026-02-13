"""
AnyCompany Food & Beverage - Sales Dashboard
Analyse des tendances de ventes
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime

# Configuration de la page
st.set_page_config(
    page_title="AnyCompany - Sales Dashboard",
    page_icon="📊",
    layout="wide"
)

# ========================================
# CONNEXION SNOWFLAKE
# ========================================

# Note: Vous devez créer un fichier .streamlit/secrets.toml avec vos identifiants
# [snowflake]
# user = "VOTRE_USER"
# password = "VOTRE_PASSWORD"
# account = "VOTRE_ACCOUNT"
# warehouse = "ANALYTICS_WH"
# database = "ANYCOMPANY_LAB"
# schema = "SILVER"

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
        """Exécuter une requête et retourner un DataFrame"""
        conn = get_snowflake_connection()
        return pd.read_sql(query, conn)
    
    SNOWFLAKE_AVAILABLE = True
except:
    SNOWFLAKE_AVAILABLE = False
    st.warning("⚠️ Snowflake non configuré. Utilisation de données de démonstration.")

# ========================================
# FONCTION POUR DONNÉES DEMO
# ========================================

def get_demo_data(query_type):
    """Retourner des données de démonstration"""
    if query_type == "kpis":
        return pd.DataFrame({
            'TOTAL_REVENUE': [85000000],
            'TOTAL_TRANSACTIONS': [125000],
            'AVG_TRANSACTION_VALUE': [680],
            'MARKETS_SERVED': [8]
        })
    elif query_type == "monthly":
        dates = pd.date_range(start='2024-01-01', periods=12, freq='MS')
        return pd.DataFrame({
            'MONTH': dates,
            'TOTAL_SALES': [7200000, 6800000, 7500000, 6500000, 6200000, 
                           6000000, 6800000, 7200000, 7500000, 8200000, 
                           9500000, 10200000],
            'NUMBER_OF_SALES': [10500, 10000, 11000, 9500, 9000, 
                               8800, 10000, 10500, 11000, 12000, 
                               14000, 15000],
            'AVG_TRANSACTION_VALUE': [686, 680, 682, 684, 689, 
                                     682, 680, 686, 682, 683, 
                                     679, 680]
        })
    elif query_type == "regional":
        return pd.DataFrame({
            'REGION': ['Europe', 'Amérique du Nord', 'Asie', 'Amérique du Sud', 'Afrique'],
            'TOTAL_SALES': [29750000, 23800000, 17000000, 8500000, 5950000],
            'NUMBER_OF_SALES': [43750, 35000, 25000, 12500, 8750]
        })
    elif query_type == "yoy":
        return pd.DataFrame({
            'TRANSACTION_YEAR': [2022, 2023, 2024, 2025],
            'TOTAL_SALES': [95000000, 92000000, 85000000, 78000000],
            'YOY_GROWTH_PCT': [None, -3.16, -7.61, -8.24]
        })
    elif query_type == "seasonality":
        return pd.DataFrame({
            'MONTH_NUMBER': list(range(1, 13)),
            'MONTH_NAME': ['January', 'February', 'March', 'April', 'May', 'June',
                          'July', 'August', 'September', 'October', 'November', 'December'],
            'TOTAL_SALES': [6800000, 6500000, 7200000, 6200000, 5800000, 5500000,
                           6800000, 7200000, 7800000, 8500000, 10200000, 11500000]
        })
    elif query_type == "payment":
        return pd.DataFrame({
            'PAYMENT_METHOD': ['Credit Card', 'Bank Transfer', 'PayPal', 'Cash'],
            'TOTAL_AMOUNT': [42500000, 25500000, 12750000, 4250000],
            'NUMBER_OF_TRANSACTIONS': [62500, 37500, 18750, 6250]
        })

# ========================================
# TITRE ET CONTEXTE
# ========================================

st.title("📊 AnyCompany Food & Beverage - Sales Analytics")

st.markdown("""
**Mission Critique** : Inverser la baisse des ventes et augmenter la part de marché de 22% à 32%

**Contexte** :
- 📉 Baisse des ventes : -15% YoY
- 💰 Budget marketing réduit de 30%
- 🎯 Objectif : +10 points de part de marché d'ici T4 2025
""")

st.markdown("---")

# ========================================
# SIDEBAR - FILTRES
# ========================================

st.sidebar.header("🔍 Filtres")
st.sidebar.info("Utilisez les filtres ci-dessous pour personnaliser l'analyse")

date_range = st.sidebar.selectbox(
    "Période d'analyse",
    ["Derniers 12 mois", "Derniers 24 mois", "Année en cours", "Tout l'historique"]
)
# Calculer le filtre SQL selon la sélection
if date_range == "Derniers 12 mois":
    date_filter = "AND transaction_date >= DATEADD(month, -12, CURRENT_DATE())"
elif date_range == "Derniers 24 mois":
    date_filter = "AND transaction_date >= DATEADD(month, -24, CURRENT_DATE())"
elif date_range == "Année en cours":
    date_filter = "AND YEAR(transaction_date) = YEAR(CURRENT_DATE())"
else:  # Tout l'historique
    date_filter = ""

# ========================================
# KPIs PRINCIPAUX
# ========================================

st.header("📈 Indicateurs Clés de Performance")

if SNOWFLAKE_AVAILABLE:
    kpi_query = """
    SELECT 
        SUM(amount) AS total_revenue,
        COUNT(*) AS total_transactions,
        ROUND(AVG(amount), 2) AS avg_transaction_value,
        COUNT(DISTINCT region) AS markets_served
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    """
    kpis = run_query(kpi_query)
else:
    kpis = get_demo_data("kpis")

col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric(
        "💰 Revenu Total",
        f"${kpis['TOTAL_REVENUE'].iloc[0]:,.0f}",
        delta="Chiffre d'affaires global"
    )

with col2:
    st.metric(
        "🛒 Transactions",
        f"{kpis['TOTAL_TRANSACTIONS'].iloc[0]:,.0f}",
        delta="Volume de ventes"
    )

with col3:
    st.metric(
        "💵 Panier Moyen",
        f"${kpis['AVG_TRANSACTION_VALUE'].iloc[0]:,.2f}",
        delta="Valeur moyenne"
    )

with col4:
    st.metric(
        "🌍 Marchés",
        f"{kpis['MARKETS_SERVED'].iloc[0]}",
        delta="Régions actives"
    )

st.markdown("---")

# ========================================
# ÉVOLUTION TEMPORELLE
# ========================================

st.header("📅 Évolution des Ventes dans le Temps")

if SNOWFLAKE_AVAILABLE:
   monthly_query = f"""
  SELECT 
    DATE_TRUNC('month', transaction_date) AS month,
    SUM(amount) AS total_sales,
    COUNT(*) AS number_of_sales,
    ROUND(AVG(amount), 2) AS avg_transaction_value
  FROM SILVER.financial_transactions_clean
  WHERE transaction_type = 'Sale'
  {date_filter}
  GROUP BY DATE_TRUNC('month', transaction_date)
  ORDER BY month
  """
   monthly_sales = run_query(monthly_query)
else:
    monthly_sales = get_demo_data("monthly")

# Graphique d'évolution
fig_monthly = go.Figure()

fig_monthly.add_trace(go.Scatter(
    x=monthly_sales['MONTH'],
    y=monthly_sales['TOTAL_SALES'],
    mode='lines+markers',
    name='Ventes Totales',
    line=dict(color='#1f77b4', width=3),
    marker=dict(size=10),
    hovertemplate='<b>%{x|%B %Y}</b><br>Ventes: $%{y:,.0f}<extra></extra>'
))

fig_monthly.update_layout(
    title="Évolution Mensuelle des Ventes (12 derniers mois)",
    xaxis_title="Mois",
    yaxis_title="Ventes ($)",
    hovermode='x unified',
    height=450,
    showlegend=True
)

st.plotly_chart(fig_monthly, use_container_width=True)

# ========================================
# PERFORMANCE RÉGIONALE
# ========================================

st.header("🌍 Performance par Région")

if SNOWFLAKE_AVAILABLE:
    regional_query = """
    SELECT 
        region,
        SUM(amount) AS total_sales,
        COUNT(*) AS number_of_sales
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY region
    ORDER BY total_sales DESC
    """
    regional_sales = run_query(regional_query)
else:
    regional_sales = get_demo_data("regional")

col1, col2 = st.columns(2)

with col1:
    # Graphique en barres
    fig_region_bar = px.bar(
        regional_sales,
        x='REGION',
        y='TOTAL_SALES',
        title="Ventes par Région",
        labels={'TOTAL_SALES': 'Ventes ($)', 'REGION': 'Région'},
        color='TOTAL_SALES',
        color_continuous_scale='Blues'
    )
    fig_region_bar.update_layout(height=400)
    st.plotly_chart(fig_region_bar, use_container_width=True)

with col2:
    # Graphique en camembert
    fig_pie = px.pie(
        regional_sales,
        values='TOTAL_SALES',
        names='REGION',
        title="Répartition du Chiffre d'Affaires",
        hole=0.4
    )
    fig_pie.update_traces(textposition='inside', textinfo='percent+label')
    fig_pie.update_layout(height=400)
    st.plotly_chart(fig_pie, use_container_width=True)

# Tableau détaillé
st.subheader("📊 Détails par Région")
regional_sales['PANIER_MOYEN'] = regional_sales['TOTAL_SALES'] / regional_sales['NUMBER_OF_SALES']
st.dataframe(
    regional_sales.style.format({
        'TOTAL_SALES': '${:,.0f}',
        'NUMBER_OF_SALES': '{:,.0f}',
        'PANIER_MOYEN': '${:,.2f}'
    }),
    use_container_width=True
)

st.markdown("---")

# ========================================
# CROISSANCE ANNUELLE
# ========================================

st.header("📊 Analyse de Croissance")

if SNOWFLAKE_AVAILABLE:
    yoy_query = """
    SELECT 
        transaction_year,
        SUM(amount) AS total_sales,
        LAG(SUM(amount)) OVER (ORDER BY transaction_year) AS previous_year_sales,
        ROUND(
            (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY transaction_year)) * 100.0 / 
            NULLIF(LAG(SUM(amount)) OVER (ORDER BY transaction_year), 0), 
        2) AS yoy_growth_pct
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY transaction_year
    ORDER BY transaction_year DESC
    LIMIT 5
    """
    yoy_growth = run_query(yoy_query)
else:
    yoy_growth = get_demo_data("yoy")

# Graphique combiné
fig_growth = go.Figure()

fig_growth.add_trace(go.Bar(
    x=yoy_growth['TRANSACTION_YEAR'],
    y=yoy_growth['TOTAL_SALES'],
    name='Ventes Annuelles',
    marker_color='lightblue',
    yaxis='y',
    hovertemplate='<b>%{x}</b><br>Ventes: $%{y:,.0f}<extra></extra>'
))

fig_growth.add_trace(go.Scatter(
    x=yoy_growth['TRANSACTION_YEAR'],
    y=yoy_growth['YOY_GROWTH_PCT'],
    name='Croissance YoY (%)',
    yaxis='y2',
    mode='lines+markers',
    line=dict(color='red', width=3),
    marker=dict(size=12),
    hovertemplate='<b>%{x}</b><br>Croissance: %{y:.2f}%<extra></extra>'
))

fig_growth.update_layout(
    title="Ventes Annuelles et Croissance Year-over-Year",
    xaxis_title="Année",
    yaxis=dict(title="Ventes ($)"),
    yaxis2=dict(
        title="Croissance YoY (%)",
        overlaying='y',
        side='right'
    ),
    hovermode='x unified',
    height=450
)

st.plotly_chart(fig_growth, use_container_width=True)

# Alerte si croissance négative
if yoy_growth['YOY_GROWTH_PCT'].iloc[0] < 0:
    st.error(f"⚠️ **ALERTE** : Croissance négative de {yoy_growth['YOY_GROWTH_PCT'].iloc[0]:.2f}% sur la dernière année !")
    st.info("💡 **Action recommandée** : Consulter le document business_insights.md pour les recommandations stratégiques")

st.markdown("---")

# ========================================
# SAISONNALITÉ
# ========================================

st.header("🌡️ Analyse de Saisonnalité")

if SNOWFLAKE_AVAILABLE:
    seasonality_query = """
    SELECT 
        MONTH(transaction_date) AS month_number,
        TO_CHAR(transaction_date, 'Month') AS month_name,
        SUM(amount) AS total_sales
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY MONTH(transaction_date), TO_CHAR(transaction_date, 'Month')
    ORDER BY month_number
    """
    seasonality = run_query(seasonality_query)
else:
    seasonality = get_demo_data("seasonality")

fig_season = px.bar(
    seasonality,
    x='MONTH_NAME',
    y='TOTAL_SALES',
    title="Saisonnalité des Ventes (Moyenne Mensuelle)",
    labels={'TOTAL_SALES': 'Ventes Totales ($)', 'MONTH_NAME': 'Mois'},
    color='TOTAL_SALES',
    color_continuous_scale='Viridis'
)
fig_season.update_layout(height=400)
st.plotly_chart(fig_season, use_container_width=True)

# Identifier pic et creux
max_month = seasonality.loc[seasonality['TOTAL_SALES'].idxmax(), 'MONTH_NAME']
min_month = seasonality.loc[seasonality['TOTAL_SALES'].idxmin(), 'MONTH_NAME']

col1, col2 = st.columns(2)
with col1:
    st.success(f"📈 **Pic saisonnier** : {max_month}")
with col2:
    st.warning(f"📉 **Creux saisonnier** : {min_month}")

st.markdown("---")

# ========================================
# MÉTHODES DE PAIEMENT
# ========================================

st.header("💳 Analyse des Méthodes de Paiement")

if SNOWFLAKE_AVAILABLE:
    payment_query = """
    SELECT 
        payment_method,
        COUNT(*) AS number_of_transactions,
        SUM(amount) AS total_amount
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY payment_method
    ORDER BY total_amount DESC
    """
    payment_methods = run_query(payment_query)
else:
    payment_methods = get_demo_data("payment")

col1, col2 = st.columns(2)

with col1:
    fig_payment = px.bar(
        payment_methods,
        x='PAYMENT_METHOD',
        y='TOTAL_AMOUNT',
        title="Volume de Ventes par Méthode de Paiement",
        labels={'TOTAL_AMOUNT': 'Montant Total ($)', 'PAYMENT_METHOD': 'Méthode'},
        color='TOTAL_AMOUNT',
        color_continuous_scale='Oranges'
    )
    st.plotly_chart(fig_payment, use_container_width=True)

with col2:
    st.subheader("📋 Détails")
    payment_methods['PCT_VOLUME'] = payment_methods['TOTAL_AMOUNT'] / payment_methods['TOTAL_AMOUNT'].sum() * 100
    st.dataframe(
        payment_methods.style.format({
            'NUMBER_OF_TRANSACTIONS': '{:,.0f}',
            'TOTAL_AMOUNT': '${:,.0f}',
            'PCT_VOLUME': '{:.2f}%'
        }),
        use_container_width=True
    )

st.markdown("---")

# ========================================
# INSIGHTS CLÉS
# ========================================

st.header("💡 Insights Clés & Recommandations")

col1, col2, col3 = st.columns(3)

with col1:
    st.info("""
    **📊 Tendance Globale**
    - Analyse sur 12 mois
    - Identification des baisses
    - Opportunités de croissance
    
    👉 Voir business_insights.md
    """)

with col2:
    st.success("""
    **🌍 Régions Performantes**
    - Top 3 identifiées
    - Potentiel de réplication
    - Stratégies gagnantes
    
    👉 Focus sur l'Asie (+8% YoY)
    """)

with col3:
    st.warning("""
    **⚠️ Points d'Attention**
    - Régions sous-performantes
    - Saisonnalité à anticiper
    - Actions correctives
    
    👉 Plan d'action prioritaire
    """)

# ========================================
# FOOTER
# ========================================

st.markdown("---")
st.markdown(f"""
**AnyCompany Food & Beverage** - Sales Analytics Dashboard  
*Dernière mise à jour : {datetime.now().strftime("%d/%m/%Y %H:%M")}*  
📧 Contact : magueyefall1306@gmail.com
""")

# Note sur les données
if not SNOWFLAKE_AVAILABLE:
    st.info("ℹ️ **Mode Démonstration** : Configurez Snowflake dans `.streamlit/secrets.toml` pour utiliser les vraies données.")