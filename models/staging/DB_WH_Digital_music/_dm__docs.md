{% docs dm_overview %}

## Digital Music

Domaine couvrant la plateforme de vente de musique dématérialisée du groupe (catalogue de type
Chinook) : artistes, albums, pistes, genres, playlists, ainsi que les clients, employés (support)
et la facturation associée.

Schéma source ClickHouse : `DB_WH_DIGITAL_MUSIC` — 11 tables, staging avec le préfixe `stg_dm_*`.

### Périmètre fonctionnel

**Catalogue**
`artist`, `album`, `genre`, `media_type`, `track`

**Playlists**
`playlist`, `playlist_track`

**Clients & support**
`customer`, `employee`

**Facturation**
`invoice`, `invoice_line`

### Conventions de staging

- Toutes les vues `stg_dm_*` sont matérialisées en `view` et taguées `staging`, `digital_music`.
- Contrairement au domaine Digital Gaming, les tables sources exposent déjà des clés primaires
  explicites (`album_id`, `artist_id`, `customer_id`, ...) : aucun renommage d'`id` générique
  n'est nécessaire, les modèles staging se contentent de typer les colonnes.
- Les colonnes nullables côté source sont castées en `Nullable(...)` pour préserver le
  comportement d'origine (ex : `customer.support_rep_id`, `employee.reports_to`, `track.genre_id`).
- `playlist_track` est une table de jointure pure (association playlists/pistes) : elle n'a pas de
  clé primaire propre et expose directement ses deux clés étrangères.

### Relations clés

- `artist` → `album` → `track` (via `artist_id` / `album_id`)
- `track` → `genre` / `media_type` (via `genre_id` / `media_type_id`)
- `playlist` ↔ `track` via `playlist_track`
- `customer` → `invoice` → `invoice_line` → `track`
- `customer.support_rep_id` → `employee`, `employee.reports_to` → `employee` (hiérarchie interne)

{% enddocs %}
