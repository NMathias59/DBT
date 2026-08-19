{% docs imdb_overview %}

## IMDB (référentiel films)

Domaine de référence films/casting (jeu de données de type export IMDb) : films, personnes
(cast/crew), crédits (jonction film/personne/rôle), genres, langues, durées.

Schéma source ClickHouse : `DB_WH_IMDB_REFERENCE` (dossier de domaine `DB_WH_IMDB` -- nom
différent du schéma, déjà en place dans le projet avant ce domaine) — 11 tables, staging avec le
préfixe `stg_imdb_*`.

### Périmètre fonctionnel

**Catalogue**
`movies`, `genres`, `languages`, `running_times`

**Cast & crew**
`people`, `credits`

**Tables vides sur ce jeu de données** (0 ligne, vues créées pour la complétude mais non
consommées par intermediate/marts) : `certificates`, `color_info`, `keywords`, `locations`,
`release_dates`.

### Particularités du domaine

- **Pas de colonne exploitable** : `people.gender` et `credits.position`/`line_order`/
  `group_order`/`subgroup_order` sont 100% NULL sur ce jeu de données -- conservées telles
  quelles en staging (comportement source), non utilisées en intermediate/marts.
- **`languages.note` mal nommée** : contient systématiquement (quand renseignée) le titre du
  film dans cette langue, pas une note libre -- particularité du jeu de données, conservée
  telle quelle (nom de colonne source non modifié).
- **`running_times.running_time`** : `String` en source mais toujours numérique sur ce jeu de
  données (pas de format composite type "USA:118") -- casté directement en minutes en staging.
- **Pas de dimension temporelle fine** : contrairement aux autres domaines (ventes, notes),
  aucune table n'a de timestamp événementiel -- `movies.year` (grain annuel) est le seul axe
  temporel disponible. Aucun fait de ce domaine n'est donc incrémental (pas de date à
  partitionner).

### Conventions de staging

- Toutes les vues `stg_imdb_*` sont matérialisées en `view` et taguées `staging`, `imdb`.
- `movies.id`/`people.id` renommés en `movie_id`/`person_id` explicites, comme pour Digital
  Gaming (`id` générique -> `<entité>_id`).

### Relations clés

- `movies` ← `credits` → `people` (jonction film/personne/rôle, `credits.type` = actor/
  director/writer/producer/composer/cinematographer/editor/production_designer/self/
  archive_footage/archive_sound)
- `movies` → `genres` / `languages` / `running_times` (1:N ou 1:1 selon la table)

{% enddocs %}
