cat > evidence/audit/CONCLUSION.md <<'EOF'
# Audit avec pgAudit
## Configuration vérifiée
* `shared_preload_libraries` contient `pgaudit` et `pg_stat_statements`.
* L’extension `pgaudit` version 18.0 est créée dans la base `retailops`.
* `pgaudit.log` est configuré sur `ddl, role, write`.
* `pgaudit.log_parameter` est désactivé afin de ne pas journaliser les paramètres transmis.
* `pgaudit.log_relation` est activé.
* Le rôle `auditeur` est utilisé comme rôle d’audit objet.
## Actions journalisées
Les journaux contiennent des événements pour :
* création des extensions ;
* modification de la configuration via `ALTER SYSTEM` ;
* création du rôle `auditeur` ;
* attribution du droit de lecture sur `retail.customers` ;
* création et suppression de `retail.audit_demo` ;
* mise à jour d’une commande ;
* lecture de `retail.customers`.
## Expurgation
Le fichier `audit_expurge.log` conserve uniquement les lignes contenant `AUDIT:`. Les paramètres d’exécution ne sont pas journalisés grâce à `pgaudit.log_parameter = off`.

Le journal brut reste hors du dépôt et doit faire l’objet d’une relecture avant toute diffusion.
EOF