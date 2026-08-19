{% docs dv_overview %}

## Digital Video

Domaine couvrant le catalogue de films et l'activité d'évaluation du groupe (jeu de données de
type MovieLens) : films, identifiants externes (IMDb/TMDb), notes et tags posés par les
utilisateurs.

Schéma source ClickHouse : `DB_WH_DIGITAL_VIDEO` — 4 tables, staging avec le préfixe `stg_dv_*`.

### Périmètre fonctionnel

**Catalogue**
`movies`, `links` (identifiants externes IMDb/TMDb)

**Activité utilisateur**
`ratings`, `tags`

### Particularité du domaine : pas de table utilisateur

Contrairement à Digital Gaming (`users`) et Digital Music (`customer`), ce domaine n'a **aucune
table utilisateur dédiée** : `userId` n'existe que comme clé étrangère dans `ratings`/`tags`. La
dimension utilisateur (`DIM_VIEWERS` en mart) est donc entièrement dérivée de l'activité
(union des `userId` distincts de `ratings`/`tags`), pas d'une source dédiée — aucune information
descriptive (nom, email...) n'est disponible pour ces utilisateurs.

### Conventions de staging

- Toutes les vues `stg_dv_*` sont matérialisées en `view` et taguées `staging`, `digital_video`.
- `movies.genres` est conservé brut (chaîne pipe-délimitée, ex : `Adventure|Comedy`, sentinelle
  `(no genres listed)` si aucun genre) : l'éclatement en tableau est fait en intermediate
  (`int_dv_movies`), pas en staging.
- `ratings.timestamp`/`tags.timestamp` (epoch Unix en secondes côté source) sont convertis en
  `datetime` dès le staging (`rated_at`/`tagged_at`) : c'est un nettoyage de type, pas de la
  logique métier, contrairement à l'éclatement des genres.
- `links.imdb_id` est conservé en `String` (toujours 7 chiffres sur ce jeu de données, zéros non
  significatifs) plutôt que casté en nombre.

### Relations clés

- `movies` ↔ `links` (1:1 sur `movie_id`)
- `movies` → `ratings` / `tags` (via `movie_id`)
- Pas de dimension utilisateur source : `ratings`/`tags` sont les seules traces de `userId`.

{% enddocs %}
