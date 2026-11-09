# Photographies à fournir — document de travail

Ce fichier reste dans les sources et ne doit pas être publié. Les images ne sont pas encore fournies. Les descriptions ci-dessous indiquent une intention, sans affirmer qu’un atelier a déjà été documenté.

| Page / emplacement | Identifiant | Photographie attendue | Proportions ordinateur / mobile |
| --- | --- | --- | --- |
| Accueil, ouverture | `hero` | Un artisan au travail, avec la personne, le geste et la matière dans le même cadre. | 4:5 / 4:3 |
| Accueil, « Tout commence par une rencontre » | `homeEncounter` | Une rencontre dans un atelier ou un échange pendant la documentation. | 5:4 / 4:3 |
| Association, raison d’être | `project` | Un atelier habité : la personne, son environnement et le travail en cours. | 5:4 / 4:3 |
| Association, contribution collective | `projectExchange` | Un échange dans un atelier autour d’un outil, d’une matière ou d’un objet. | 4:3 / 4:3 |
| Démarche, ouverture | `approach` | L’observation d’un geste précis, avec l’outil et la matière visibles. | 5:4 / 4:3 |
| Démarche, les cinq étapes | `approachInterview` | Un entretien ou une explication de l’artisan pendant la documentation de son travail. | 4:5 / 4:3 |
| Démarche, sources et contexte | `approachDetail` | Un détail d’outil, de matière ou de surface de travail qui situe la pratique. | 4:3 / 4:3 |

Quelques images peuvent servir à plusieurs emplacements si leur contenu et leurs droits s’y prêtent ; les sept emplacements ne demandent pas sept séances photographiques.

Pour chaque image, fournir le fichier original, sa provenance, l’autorisation d’utilisation, le crédit à afficher et le contexte réel. La légende éventuelle et le texte alternatif seront rédigés après examen de la photographie. Ne pas attribuer une image illustrative à un projet de l’association.

Les champs sont dans `src/_data/images.json`. Les fichiers image vont dans `src/assets/`. Le cadrage se règle séparément avec `focalPoint` et `focalPointMobile`. Les dimensions réelles, les proportions, la légende et le crédit sont pris en charge par les composants existants ; aucune nouvelle refonte n’est nécessaire.

Les indications apparaissent seulement dans l’aperçu de travail. Le build de production omet les images manquantes et adapte les colonnes, sans cadre vide ni consigne de travail. Utiliser `npm run build:layout-preview` pour contrôler cette mise en page avant la configuration publique définitive.
