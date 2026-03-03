# Pipeline de données Snowflake

Projet de déploiement d'un pipeline de traitement de logs d'application de santé sur Snowflake.
Les données brutes sont ingérées, validées (qualité, arrivées tardives), enrichies par process,
puis les résultats sont tracés dans des tables de monitoring.

---

## Structure du projet

projet_final/
1. admin_RBAC.sql:  Création des rôles et hiérarchie RBAC
2. dev_sec_ops_RBAC.sql: Création de la DB, schemas, grants par rôle
3. create_table.sql: Création de toutes les tables (RAW, COMMON, STAGING)
4. ingestion.sql: File format CSV, stage interne, pipe d'ingestion
5. create_function.sql: UDFs SQL & Python (validation, extraction)
6. create_procedure.sql: Stored procedures du pipeline de transformation
7. create_task.sql: Task graph + stream + activation
8. deploy.sh: Script de déploiement automatisé via Snowflake CLI
9. config.toml: Configuration de connexion Snowflake CLI (non versionné)


---

## Architecture

### Base de données : `HEALT_APP_PROJET`

| Schéma | Rôle | Contenu |
|--------|------|---------|
| `RAW` | Ingestion brute | `raw_events`, stage, file format, pipe |
| `COMMON` | Transformation & monitoring | `data_to_process`, `data_anomalies`, `logging`, `transformation_pipeline_status` |
| `STAGING` | Données enrichies par process | 10 tables (une par `process_name`) |

### Task Graph

```
identify_new_data_task   (déclenchée par stream)
        │ └── finalize_transformation  (FINALIZE)
data_quality_task
        │
arrivees_tardives
        ├── hih_listener_manager
        ├── hih_hibroadcastutil
        ├── step_standstepcounter
        ├── step_sputils
        ├── step_lsc
        ├── hih_hihealthdatainsertstore
        ├── hih_datastatmanager
        ├── hih_hisyncutil
        ├── step_standreportreceiver
        └── step_screenutil
               
```

### RBAC — Hiérarchie des rôles

```
ACCOUNTADMIN
    └── dev_sec_ops_role
            ├── dev_ops_role    → CREATE TABLE, PROCEDURE, FUNCTION, FILE FORMAT, STAGE, PIPE
            ├── app_role        → CREATE TASK, EXECUTE TASK, SELECT/INSERT sur les tables
            └── engineer_role   → SELECT uniquement, MONITOR sur les tasks
```

---

## Prérequis

- [Snowflake CLI](3.15.0) installé 
- Un compte Snowflake actif avec un utilisateur ayant `ACCOUNTADMIN`
- Python 3.12+ (pour les UDFs Python)

---

## Déploiement

### 1. Étape manuelle (une seule fois)

Se connecter à l'interface web Snowflake avec le compte admin et exécuter :

```sql
USE ROLE ACCOUNTADMIN;
GRANT ROLE ACCOUNTADMIN TO USER DEPLOYMENT_USER;
```

> Remplacer `DEPLOYMENT_USER` par le nom d'utilisateur configuré dans `config.toml`.

### 2. Configurer `config.toml`

Créer un fichier `config.toml` à la racine du projet :

```toml
[connections.default]
account   = "VOTRE_ACCOUNT_IDENTIFIER"
user      = "DEPLOYMENT_USER"
password  = "VOTRE_MOT_DE_PASSE"
warehouse = "COMPUTE_WH"
```

### 3. Vérifier la connexion

```bash
snow --config-file ./config.toml connection test
```

### 4. Lancer le déploiement

```bash
chmod +x deploy.sh
./deploy.sh
```

