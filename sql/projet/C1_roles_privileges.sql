-- sql/projet/04_roles.sql — à exécuter en tant que propriétaire (postgres)
-- Les mots de passe sont passés par variable psql
-- Usage : psql -v analyst_pwd="$ANALYST_PWD" -v app_pwd="$APP_PWD" -f 04_roles.sql

-- 0. Durcissement : retirer les droits implicites de PUBLIC
REVOKE ALL ON DATABASE retailops FROM PUBLIC;
REVOKE ALL ON SCHEMA   public    FROM PUBLIC;
REVOKE ALL ON SCHEMA   retail    FROM PUBLIC;

-- 1. Rôles de groupe (sans connexion)
CREATE ROLE retail_ro NOLOGIN;
CREATE ROLE retail_rw NOLOGIN;

-- 2. Utilisateurs
CREATE ROLE analyst_login
LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    NOBYPASSRLS
CONNECTION LIMIT 10;

CREATE ROLE app_login
LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    NOBYPASSRLS
CONNECTION LIMIT 20;

GRANT retail_ro TO analyst_login;
GRANT retail_rw TO app_login;

-- 3. Accès à la base et au schéma
GRANT CONNECT ON DATABASE retailops TO retail_ro, retail_rw;
GRANT USAGE   ON SCHEMA   retail    TO retail_ro, retail_rw;

-- 4. Lecture seule
GRANT SELECT ON ALL TABLES IN SCHEMA retail TO retail_ro;

-- 5. Écritures métier : la liste est volontairement minimale
GRANT SELECT ON ALL TABLES IN SCHEMA retail TO retail_rw;
GRANT INSERT, UPDATE ON retail.orders       TO retail_rw;
GRANT INSERT, UPDATE ON retail.order_items  TO retail_rw;
GRANT INSERT, UPDATE ON retail.customers    TO retail_rw;
-- Pas de DELETE, pas de TRUNCATE, aucun droit sur products (catalogue géré à part).

-- 6. Objets futurs
ALTER DEFAULT PRIVILEGES IN SCHEMA retail GRANT SELECT ON TABLES TO retail_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA retail GRANT SELECT ON TABLES TO retail_rw;

-- 7. Vérification déclarative
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS droits
FROM   information_schema.role_table_grants
WHERE  table_schema = 'retail' AND grantee IN ('retail_ro','retail_rw')
GROUP BY grantee, table_name ORDER BY grantee, table_name;