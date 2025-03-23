#!/bin/bash

# Mettre à jour les packages
sudo apt-get update -y

# Installer Python et pip
sudo apt-get install -y python3 python3-pip

# Installer Flask
pip3 install flask

# Créer un fichier Python pour l'application Flask
cat <<EOL > /home/azureuser/app.py
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL

# Exécuter l'application Flask
nohup python3 /home/azureuser/app.py &
