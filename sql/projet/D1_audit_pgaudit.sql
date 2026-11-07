-- =====================================================================
-- Projet RetailOps - Activation et configuration de pgAudit et pg_stat_statements
-- =====================================================================

-- 1. Création des extensions nécessaires dans la base de données
CREATE EXTENSION IF NOT EXISTS pgaudit;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 2. Configuration des paramètres de session et d'audit
-- Session : trace les changements de structure (DDL), de droits (role) et les écritures (write)
ALTER SYSTEM SET pgaudit.log = 'ddl, role, write';
ALTER SYSTEM SET pgaudit.log_parameter = off;         -- Évite de journaliser des données personnelles (ex: e-mails)
ALTER SYSTEM SET pgaudit.log_relation = on;          -- Force l'affichage d'une ligne par table touchée
ALTER SYSTEM SET pgaudit.log_statement_once = on;

-- 3. Configuration de l'audit spécifique par rôle (Objet)
-- Création d'un rôle dédié à l'audit et octroi d'un accès en lecture seule sur la table sensible customers
CREATE ROLE auditeur NOLOGIN;
GRANT SELECT ON retail.customers TO auditeur;
ALTER SYSTEM SET pgaudit.role = 'auditeur';

-- 4. Application dynamique des modifications de configuration
SELECT pg_reload_conf();

-- 5. Commandes de vérification (à exécuter pour les preuves)
SHOW shared_preload_libraries;
SHOW pgaudit.log;
SELECT extname, extversion FROM pg_extension WHERE extname = 'pgaudit';

#preuve d'audit expurgée
``` 2026-11-07 09:23:28.510 UTC [4105] LOG:  AUDIT: SESSION,1,1,DDL,CREATE SEQUENCE,SEQUENCE,retail.audit_test_id_seq,"CREATE TABLE retail.audit_test (id SERIAL PRIMARY KEY, info VARCHAR(50));",<not logged>
2026-11-07 09:23:28.510 UTC [4105] LOG:  AUDIT: SESSION,1,1,DDL,CREATE TABLE,TABLE,retail.audit_test,<previously logged>,<previously logged>
2026-11-07 09:23:28.511 UTC [4105] LOG:  AUDIT: SESSION,1,1,DDL,CREATE INDEX,INDEX,retail.audit_test_pkey,<previously logged>,<previously logged>
2026-11-07 09:23:28.511 UTC [4105] LOG:  AUDIT: SESSION,1,1,DDL,ALTER SEQUENCE,SEQUENCE,retail.audit_test_id_seq,<previously logged>,<previously logged>```