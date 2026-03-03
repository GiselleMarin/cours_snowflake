#!/bin/bash
set -e  # arrête le script si une commande échoue

CONFIG="--config-file ./config.toml"

echo ">>> 1. Admin RBAC (roles + hiérarchie)"
snow $CONFIG sql --role ACCOUNTADMIN \
  -f projet_final/1_admin_RBAC.sql

echo ">>> 2. DevSecOps RBAC (DB, schemas, grants)"
snow $CONFIG sql --role dev_sec_ops_role \
  --database HEALT_APP_PROJET \
  -f projet_final/2_dev_sec_ops_RBAC.sql

echo ">>> 3. Tables"
snow $CONFIG sql --role dev_ops_role \
  --database HEALT_APP_PROJET \
  -f projet_final/3_create_table.sql

echo ">>> 4. Ingestion (file formats, stages)"
snow $CONFIG sql --role dev_ops_role \
  --database HEALT_APP_PROJET --schema RAW \
  -f projet_final/4_ingestion.sql

echo ">>> 5. Fonctions"
snow $CONFIG sql --role dev_ops_role \
  --database HEALT_APP_PROJET \
  -f projet_final/5_create_function.sql

echo ">>> 6. Procédures"
snow $CONFIG sql --role dev_ops_role \
  --database HEALT_APP_PROJET \
  -f projet_final/6_create_procedure.sql

echo ">>> 7. Tasks"
snow $CONFIG sql --role app_role \
  --database HEALT_APP_PROJET \
  -f projet_final/7_create_task.sql

echo "Déploiement terminé !"