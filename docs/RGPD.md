# Conformité RGPD — RetailOps

<div align="center">

# Conformité RGPD — RetailOps

![RGPD](https://img.shields.io/badge/RGPD-Conformit%C3%A9%20RGPD-blue?&logo=gdpr&logoColor=white) ![Donn%C3%A9es synth%C3%A9tiques](https://img.shields.io/badge/Donn%C3%A9es-100%25%20synth%C3%A9tiques-informational?&logo=database&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-SCRAM%20SHA%20256-336791?&logo=postgresql&logoColor=white) ![pgAudit](https://img.shields.io/badge/pgAudit-Journalisation%20expurg%C3%A9e-orange?&logo=postgresql&logoColor=white) ![Chiffrement](https://img.shields.io/badge/Sauvegardes-Chiffr%C3%A9es%20GPG%20%2F%20AES%20256-success?&logo=lock&logoColor=white) ![Secrets](https://img.shields.io/badge/Secrets-Hors%20d%C3%A9p%C3%B4t%20Git-red?&logo=github&logoColor=white) ![Purge](https://img.shields.io/badge/R%C3%A9tention-Purge%20automatis%C3%A9e-yellow?&logo=clock&logoColor=white)

</div>

> Données 100 % synthétiques (aucune personne réelle). Ce document applique néanmoins
> la méthode comme si elles étaient réelles, afin de démontrer les mesures attendues.
## 1. Données traitées
Table | Données personnelles | Catégorie | Sensibilité
---|---|---|---
`customers` | `full_name`, `email`, `region`, `created_at` | Identification, contact | Moyenne (identifiant direct)
`orders` | `customer_id`, `ordered_at`, `status`, `channel` | Comportement d'achat (rattachable) | Moyenne (donnée de pseudonymisation)
`order_items` | via `order_id` | Contenu du panier | Faible à moyenne
`products` | aucune | Catalogue | Nulle

>> Le système ne traite pas les données sensibles (au sens du RGPD).

## 2. Matrice rôles / données / finalités
Rôle | Utilisateur | Données accessibles | Privilèges | Finalité | Base légale
---|---|---|---|---|---
`retail_ro` | `analyst_login` | Toutes tables du schéma `retail` | SELECT | Analyses statistiques équipes Data | Intérêt légitime
`retail_rw` | `app_login` | `orders`, `order_items`, `customers` (écriture) ; lecture du reste | SELECT, INSERT, UPDATE | Enregistrement et suivi des commandes | Exécution du contrat | 
administrateur | `postgres` | Tout | Tous | Exploitation, sauvegarde, incident | Obligation de sécurité (art. 32)

Amélioration à discuter : une vue `retail.customers_analytics` sans `full_name` ni `email`, accordée à `retail_ro` à la place de la table. L'analyste n'a pas besoin d'identifier les personnes.
## 3. Principes appliqués
* **Minimisation (art. 5.1.c)** : l'analyste ne reçoit que la lecture ; l'application n'a ni DELETE ni TRUNCATE.
* **Limitation des finalités (art. 5.1.b)** : une finalité par rôle, documentée ci-dessus.
* **Protection dès la conception (art. 25)** : droits `PUBLIC` retirés, `ALTER DEFAULT PRIVILEGES` pour les objets futurs.
* **Sécurité (art. 32)** : SCRAM-SHA-256, TLS obligatoire (`hostssl`), audit pgAudit.
## 4. Durées de conservation des données
Typologie de donnée | Durée de conservation | Justification légale & réglementaire
---|---|---
**Commandes et facturation** | **10 ans** (archivage intermédiaire) | Obligation légale : Code de commerce (art. L123-22) et Code général des impôts.
**Clients actifs** | Durée de la relation contractuelle | Exécution du contrat commercial (gestion du compte).
**Clients inactifs (prospects)** | **3 ans** après le dernier contact actif | Recommandation CNIL relative aux fichiers clients-prospects. Purge automatisée.
**Journaux techniques & pgAudit** | **6 mois à 1 an** | Référentiel CNIL sur les mesures de traçabilité. Durée proportionnée limitant les risques d'intrusion.
## 5. Gouvernance des sauvegardes et droit à l'effacement
* Les dumps (retail_admin.dump) et les archives WAL (wal_archive) contiennent les données personnelles : stockage chiffré au repos, accès restreint (chmod 600) et exclusion stricte du dépôt Git (.gitignore).
* Une donnée supprimée ou anonymisée en base subsiste dans les sauvegardes et les journaux WAL jusqu'à leur expiration : fixer une rétention courte et glissante (ex. 30 jours) alignée sur la politique de conservation.
* Le droit à l'effacement s'applique par anonymisation de full_name et email en base active, afin de conserver les commandes pour les obligations comptables.
* En cas de restauration d'un dump antérieur, les données effacées réapparaissent : la procédure impose de rejouer systématiquement le journal des demandes d'effacement après chaque restauration.
## 6. Protection et expurgation des journaux techniques
* Neutraliser les données : Le paramètre `pgaudit.log_parameter = off` empêche l'écriture de valeurs personnelles dans les journaux.
* Isoler les secrets : L'audit de session est temporairement désactivé `pgaudit.log = none` lors des commandes de gestion des mots de passe pour éviter toute fuite d'empreintes.
* Restreinde l'accès : La lecture des journaux est strictement réservée aux administrateurs afin de limiter les risques de détournement, conformément aux recommandations de la CNIL.
* Expurger obligatoirement : Les journaux bruts `audit.raw.log` restent confinés sur l'hôte. Seul un extrait expurgé `audit_expurge.log`, nettoyé des adresses IP et des e-mails, est versionné dans le dossier "evidence/"
## 7. Risques résiduels
Risque  | Mesure | Action
---|---|---
**Re-identification par l'analyste** | Surveillance et journalisation des requêtes `SELECT` via pgAudit | Déploiement d'une vue de pseudonymisation (`customers_analytics`) masquant les colonnes d'identité
**Certificat TLS d'exercice** | Autorité de certification (CA) locale dédiée et validation stricte `verify-full` | Remplacement par un certificat émis par la PKI d'entreprise ou une autorité publique reconnue
**Exposition des secrets d'infrastructure** | Isolation hors dépôt Git (`secrets/pg_superuser_password.txt`, fichier `.env` ignoré) | Intégration d'un coffre-fort d'entreprise (HashiCorp Vault, AWS Secrets Manager ou Docker Secrets)
**Copie illégitime du fichier dump** | Restriction des droits d'accès système et exclusion explicite dans `.gitignore` | Chiffrement symétrique systématique des dumps au repos (`GPG` / `AES-256`) avant archivage
**Perte des archives WAL locales** | Montage sur volume conteneurisé distinct (`wal_archive`) | Réplication distante chiffrée hors site vers un stockage immuable (Object Storage S3 WORM)
**Rétention non maîtrisée des archives** | Procédures de suppression manuelle documentées | Automatisation de la purge des dumps et des journaux d'audit par ordonnanceur sécurisé