

-- Création des rôles + hiérarchie

USE ROLE ACCOUNTADMIN;

-- Créer les 4 rôles
CREATE ROLE IF NOT EXISTS dev_sec_ops_role;
CREATE ROLE IF NOT EXISTS dev_ops_role;

CREATE ROLE IF NOT EXISTS app_role;
CREATE ROLE IF NOT EXISTS engineer_role;

GRANT ROLE ACCOUNTADMIN TO USER DEPLOYMENT_USER;
GRANT ROLE dev_sec_ops_role TO USER DEPLOYMENT_USER;


-- Hiérarchie : DevSecOps est parent des 3 rôles 

GRANT ROLE dev_ops_role  TO ROLE dev_sec_ops_role;
GRANT ROLE app_role      TO ROLE dev_sec_ops_role;
GRANT ROLE engineer_role TO ROLE dev_sec_ops_role;

-- 2. Maintenant accorder les privilèges compte

GRANT CREATE DATABASE, CREATE USER, CREATE ROLE ON ACCOUNT TO ROLE dev_sec_ops_role;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE dev_sec_ops_role;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE dev_sec_ops_role;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE dev_sec_ops_role WITH GRANT OPTION;