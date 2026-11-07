# Performance SQL — RetailOps
<!-- ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-EXPLAIN%20ANALYZE-336791)
![Bash](https://img.shields.io/badge/Bash-tests-4EAA25?logo=gnubash&logoColor=white) -->
## Objectif
Mesurer la recherche des vingt commandes les plus récentes d'un client.
## Protocole
* Même requête et mêmes données avant/après.
* Statistiques actualisées avant la comparaison.
* Une exécution d'échauffement par configuration.
* Cinq mesures par configuration.
* Aucune écriture concurrente volontaire pendant le test.
## Résultats
Indicateur | Avant | Après
---|---|---
Parcours principal | À renseigner | À renseigner
Tri explicite | À renseigner | À renseigner
Temps d'exécution médian | À calculer | À calculer
Buffers du nœud racine | À renseigner | À renseigner
Taille de l'index ajouté | Sans objet | À renseigner
## Arbitrages
Évaluer le gain de lecture au regard du stockage supplémentaire
et du travail de maintenance de l'index lors des écritures.
## Limites
Petit jeu de données, cache échauffé et environnement Docker local.
Ces mesures ne démontrent pas les performances d'une production.