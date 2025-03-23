# Application Flask avec Azure Blob Storage et MySQL

Ce projet permet de télécharger des fichiers vers Azure Blob Storage et de stocker leurs métadonnées dans une base de données MySQL. L'application expose une API RESTful avec les routes suivantes :

- **/upload** : Pour uploader un fichier dans Azure Blob Storage.
- **/download/<blob_name>** : Pour télécharger un fichier depuis Azure Blob Storage.
- **/file/<int:file_id>** : Pour obtenir les métadonnées d'un fichier depuis la base de données MySQL.
- **/file/<int:file_id> (PUT)** : Pour mettre à jour les métadonnées d'un fichier.
- **/file/<int:file_id> (DELETE)** : Pour supprimer un fichier de Azure Blob Storage et de la base de données MySQL.

## Prérequis

Avant de commencer, assurez-vous d'avoir les éléments suivants installés sur votre machine :

- **Terraform** (pour déployer l'infrastructure Azure)
- **Azure CLI** (pour gérer Azure)
- **SSH** (pour accéder à la VM distante)
- **Python 3**
- **pip** (pour installer les dépendances Python)

## Déploiement de l'infrastructure

### 1. Clonez ce dépôt

Clonez le dépôt GitHub contenant l'infrastructure et les scripts :

```bash
git clone https://github.com/JovickT/Flask.git
cd Flask/Terraform

```
### Étape 2 : Initialiser Terraform

```bash
terraform init

```

### Étape 3 : Appliquer la configuration Terraform

```bash
terraform apply

```

### Étape 4 : Obtenir l'IP publique de la VM

```bash
terraform output public_ip

```

## Configuration de la VM


### Étape 1 : Connexion à la VM via SSH

```bash
ssh azureuser@<PUBLIC_IP>

```

### Étape 2 : Ajout du script startup.sh

Le script startup.sh s'exécute automatiquement lors de la création de la VM. Il installe Python,
Flask, MySQL, et configure l'application Flask pour interagir avec Azure Blob Storage et MySQL.
Récupérer AZURE_STORAGE_ACCOUNT_KEY et MYSQL_PASSWORD qui se trouve dans le compte rendu et les intégrer dans ce fichier.

## Conclusion

---

Cette version couvre l'intégralité des étapes, de l'installation et du déploiement à la configuration de la VM,
en passant par l'utilisation de l'API Flask et des variables d'environnement. Vous pouvez suivre ce guide de A à Z pour déployer et utiliser l'application Flask sur Azure.
Pour utiliser les requêtes du backend, utiliser le compte rendu.

