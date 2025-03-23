#!/bin/bash

# Mettre à jour les packages
sudo apt-get update -y

# Installer Python 3
sudo apt-get install -y python3 python3-dev python3-distutils

# Installer pip pour Python 3
sudo apt-get install -y python3-venv python3-pip

# Installer le client MySQL
sudo apt-get install -y mysql-client

# Installer les bibliothèques nécessaires avec pip3.7
pip install --upgrade pip
pip install flask
pip install azure-storage-blob
pip install --upgrade mysql-connector-python
pip install python-dotenv

# Créer un fichier Python pour l'application Flask
cat <<EOL > /home/azureuser/app.py
import os
import mysql.connector
from flask import Flask, request, jsonify
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv

app = Flask(__name__)

# Charger les variables d'environnement
load_dotenv()

# Connexion à Azure Blob Storage
account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
account_key = os.getenv("AZURE_STORAGE_ACCOUNT_KEY")
container_name = "tchak-container"
blob_service_client = BlobServiceClient(account_url=f"https://{account_name}.blob.core.windows.net", credential=account_key)

# Connexion à MySQL
MYSQL_USER = os.getenv("MYSQL_USER", "adminuser")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "SuperSecret123!")
MYSQL_HOST = os.getenv("MYSQL_HOST", "tchak-mysql.mysql.database.azure.com")
MYSQL_DB = os.getenv("MYSQL_DB", "file_metadata")

def get_db_connection():
    return mysql.connector.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DB
    )

# 📤 Upload fichier vers Azure + stocker métadonnées en base
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "Aucun fichier fourni"}), 400

    file = request.files['file']
    blob_name = file.filename
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

    try:
        # Upload fichier vers Azure
        blob_client.upload_blob(file, overwrite=True)

        # Stocker les métadonnées en base MySQL
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO files (filename, storage_url) VALUES (%s, %s)",
            (blob_name, f"https://{account_name}.blob.core.windows.net/{container_name}/{blob_name}")
        )
        conn.commit()
        conn.close()

        return jsonify({"message": f"Fichier {blob_name} téléchargé avec succès"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 📥 Télécharger un fichier depuis Azure
@app.route('/download/<blob_name>', methods=['GET'])
def download_file(blob_name):
    try:
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        download_stream = blob_client.download_blob()
        return download_stream.readall(), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 📝 Lire les métadonnées d'un fichier
@app.route('/file/<int:file_id>', methods=['GET'])
def get_file(file_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM files WHERE id = %s", (file_id,))
        file_data = cursor.fetchone()
        conn.close()
        if file_data:
            return jsonify(file_data), 200
        else:
            return jsonify({"error": "Fichier non trouvé"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔄 Mettre à jour les métadonnées d'un fichier
@app.route('/file/<int:file_id>', methods=['PUT'])
def update_file(file_id):
    try:
        data = request.json
        new_filename = data.get("filename")

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE files SET filename = %s WHERE id = %s", (new_filename, file_id))
        conn.commit()
        conn.close()

        return jsonify({"message": "Mise à jour réussie"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🗑️ Supprimer un fichier (Azure + DB)
@app.route('/file/<int:file_id>', methods=['DELETE'])
def delete_file(file_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT filename FROM files WHERE id = %s", (file_id,))
        file_data = cursor.fetchone()

        if not file_data:
            conn.close()
            return jsonify({"error": "Fichier non trouvé"}), 404

        blob_name = file_data['filename']
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        blob_client.delete_blob()

        cursor.execute("DELETE FROM files WHERE id = %s", (file_id,))
        conn.commit()
        conn.close()

        return jsonify({"message": "Fichier supprimé avec succès"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL

# 🔹 Créer le fichier .env
cat <<EOL > /home/azureuser/.env
AZURE_STORAGE_ACCOUNT_NAME=tchakstorageacc
MYSQL_USER=adminuser
MYSQL_HOST=tchak-mysql.mysql.database.azure.com
MYSQL_DB=file_metadata
EOL

# Charger les variables d'environnement
export $(cat /home/azureuser/.env | xargs)

# 🔹 Créer la table pour stocker les fichiers (si elle n'existe pas déjà)
mysql -h \$MYSQL_HOST -u \$MYSQL_USER -p\$MYSQL_PASSWORD \$MYSQL_DB <<EOF
CREATE TABLE IF NOT EXISTS files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    storage_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Démarrer l'application Flask en arrière-plan avec Python 3.7
nohup python3 app.py &