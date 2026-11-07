# **Retail Ops - Administration de PostgreSQL**
<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.6-4169E1?logo=postgresql&logoColor=white) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white) ![SQL](https://img.shields.io/badge/SQL-scripts%20ordonn%C3%A9s-lightgrey) ![OpenSSL](https://img.shields.io/badge/TLS-OpenSSL-721412?logo=openssl&logoColor=white) ![pgAudit](https://img.shields.io/badge/Audit-pgAudit-336791) ![RGPD](https://img.shields.io/badge/Appliqué-RGPD-003399)

</div>

Vous intervenez en tant qu'administrateur de bases de données pour **RetailOps**, une entreprise de e-commerce.  
L'objectif est de déployer, sécuriser, exploiter et superviser une base de données PostgreSQL locale et reproductible.
---
## Les prérequis
Windows + WSL ou MacOS + Docker Desktop + docker compose.
## Les vérifications
```ps
# CHANGER les 3 mots de passe (".env" n'est pas versionné)
cp .env.example .env && nano .env

# Démarre et donne la version, le fichiers et les volumes
scripts/step1_architecture.sh

# Chargement du CSV, contrôles, requêtes métier
scripts/step2_data.sh

# Rôles et tests des droits
scripts/persistence_test.sh

# Rôles, droits autorisés/refusés, TLS verify-full
scripts/step3_security.sh

# PgAudit + extrait de log expurgé
scripts/step4_audit.sh

# Blocage entre 2 sessions, tailles/VACUUM
scripts/step5_transactions.sh

# Restaurer sur `retail_restore_check`, `WAL`
scripts/step6_backup.sh

# Plans avant/après, coût d'écriture, supervision
scripts/step7_perf.sh

# PASS/FAIL global
scripts/self_check.sh
```
## La structure du projet
```
retailops-postgres/
├── README.md
├── compose.yaml
├── Dockerfile                  # image postgres:17 + pgAudit
├── .env.example                # modèle sans secret ; .env est ignoré
├── .gitignore
├── config/
│   ├── postgresql.conf         # paramètres explicites
│   ├── pg_hba.conf             # SCRAM-SHA-256, hostssl
│   └── entrypoint-tls.sh       # copie des certificats avec les bons droits
├── data/                       # CSV synthétiques
├── sql/projet/
│   ├── 01_schema.sql
│   ├── 02_load.sql
│   ├── 03_controles.sql
│   ├── 04_roles.sql
│   ├── 05_audit.sql
│   ├── 06_optimisation.sql
│   └── 07_supervision.sql
├── scripts/                    # gen_certs.sh, backup.sh, restore_check.sh
├── evidence/                   # perf_before.txt, perf_after.txt, tests de droits
├── backups/                    # .gitkeep ; dumps hors Git
└── docs/                       # rgpd.md, supervision.md
```
## Sécurité, Rôles et Conformité RGPD
* **Le Chiffrement :** La connexions réseau est chiffrées.
* **Le moindre privilège :**
  * `analyst_login` (rôle groupe `retail_ro`) : accès en lecture seule (`SELECT`).
  * `app_login` (rôle groupe `retail_rw`) : droit d'écriture métier (`SELECT`, `INSERT`, `UPDATE`), sans droit de suppression (`DELETE`).
* **Traçabilité :** Activation de l'extension `pgAudit` pour consigner les opérations sensibles sans exposer les données personnelles (`pgaudit.log_parameter = off`).
## Sauvegarde & Restauration
* **La sauvegarde** 
  ```ps
  pg_dump -U postgres -Fc -d retail_admin > backups/retail_admin.dump
  ```
* **Tester la restauration :** Restauration automatisée sur une base isolée `retail_restore_check` pour garantir l'exploitabilité des données et valider les 5 000 commandes.
* **Continuité WAL :** Archivage continu des journaux de transactions pour permettre la récupération à un instant précis (PITR).
## Performance et Supervision
* **Indexation :** Optimisation d'une requête critique de recherche des commandes récentes par client (`idx_orders_customer_recent`). Les gains de temps et de tampons disque sont mesurés et comparés dans `evidence/perf_index_orders_customer_recent/`.
* **Alerting DBA :** Surveillance active des transactions prolongées, de la saturation des connexions (> 80%), des lignes mortes et des erreurs d'archivage WAL.
## Limites connues
* En mode local, le port lié à `127.0.0.1`, un seul nœud, il n'y a pas de réplication ni de haute disponibilité.
* Certificat autosigné et certificat générés localement, la clé du certificat autosigné est supprimée après signature. En production, il faut CA d'entreprise, rotation.
* Archives WAL sur un volume du même hôte. Ça ne protège pas d'une perte de machine (copie hors site à prévoir).
* Secrets, dans `.env`, est le gestionnaire de secrets en production.
* Le PITR complet sur seconde instance est décrit dans le rapport mais est non automatisé.
* L'évaluation d'`evaluation/verifier.sh` du kit n'était pas fourni, le script `scripts/self_check.sh` en est un équivalent maison.
---

## [**Le rapport est ci-joint**](rapport/rapport.pdf)
____
> #### Projet de groupe - Master IA/Data
> Esperence DAYE
> Mathieu RAMAANTSALAMA
> Hugo SUSCOSSE
> Mickael GAILLARD