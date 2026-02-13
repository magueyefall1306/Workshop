import streamlit as st
import os

st.title("Diagnostic configuration Snowflake")

# Test 1 : Répertoire courant
st.write("### Répertoire actuel")
st.code(os.getcwd())

# Test 2 : Vérifier .streamlit
streamlit_dir = os.path.join(os.getcwd(), ".streamlit")
st.write("### Dossier .streamlit")
st.write("Existe?", "✅ OUI" if os.path.exists(streamlit_dir) else "❌ NON")

# Test 3 : Vérifier secrets.toml
secrets_file = os.path.join(streamlit_dir, "secrets.toml")
st.write("### 📄 Fichier secrets.toml")
st.write("Existe?", "✅ OUI" if os.path.exists(secrets_file) else "❌ NON")

# Test 4 : Contenu du fichier
if os.path.exists(secrets_file):
    st.write("### Contenu de secrets.toml")
    with open(secrets_file, 'r', encoding='utf-8') as f:
        content = f.read()
        st.code(content, language='toml')
        st.write(f"Nombre de lignes: {len(content.splitlines())}")

# Test 5 : Secrets Streamlit
st.write("### Secrets Streamlit")
try:
    st.write("Clés:", list(st.secrets.keys()))
    if "snowflake" in st.secrets:
        st.success("Section [snowflake] trouvée!")
        st.json(dict(st.secrets["snowflake"]))
    else:
        st.error("Section [snowflake] NON trouvée")
except Exception as e:
    st.error(f"❌ Erreur: {e}")

# Test 6 : Connexion
st.write("### Test Connexion Snowflake")
try:
    import snowflake.connector
    
    conn = snowflake.connector.connect(
        user=st.secrets["snowflake"]["user"],
        password=st.secrets["snowflake"]["password"],
        account=st.secrets["snowflake"]["account"],
        warehouse=st.secrets["snowflake"]["warehouse"],
        database=st.secrets["snowflake"]["database"],
        schema=st.secrets["snowflake"]["schema"]
    )
    st.success("✅ CONNEXION RÉUSSIE!")
    conn.close()
except Exception as e:
    st.error(f"❌ Erreur connexion: {str(e)}")
