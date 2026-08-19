# dbt_clickhouse_project

Projet dbt Core connecté à ClickHouse pour la modélisation des données du groupe media/e-commerce
(gaming, musique, vidéo, procurement, etc.).

## Structure du projet

```
models/
├── staging/                       # Vues 1:1 sur les tables sources, nommage + nettoyage
│   ├── DB_WH_Digital_gaming/      # ✅ implémenté (37 tables sources)
│   ├── DB_WH_Digital_music/       # ✅ implémenté (11 tables sources)
│   ├── DB_WH_Digital_video/       # 🚧 à venir
│   ├── DB_WH_Group_procurement/   # 🚧 à venir
│   ├── DB_WH_IMDB/                # 🚧 à venir
│   ├── DB_WH_Market_intelligence/ # 🚧 à venir
│   ├── DB_WH_Physical_gaming/     # 🚧 à venir
│   ├── DB_WH_Physical_music/      # 🚧 à venir
│   ├── DB_WH_Physical_video/      # 🚧 à venir
│   ├── DB_WH_Seo_marketing/       # 🚧 à venir
│   └── DB_WH_Support_reference/   # 🚧 à venir
└── marts/                         # Modèles métier (tables), pas encore démarrés
```

Chaque dossier de domaine sous `staging/` contient (une fois implémenté) :
- `_<domaine>_sources.yml` : déclaration des tables sources ClickHouse (schéma `DB_WH_*`)
- `_<domaine>__models.yml` : documentation et `data_tests` (not_null, unique, ...) des modèles staging
- `_<domaine>__docs.md` : documentation additionnelle
- `stg_<domaine>__*.sql` : un modèle staging par table source

Materialization configurée dans `dbt_project.yml` :
- `staging` → `view`
- `intermediate` → `ephemeral`
- `marts` → `table`

## Setup

Environnement Python géré via [uv](https://docs.astral.sh/uv/), venv déjà créée dans `.venv/`.

```powershell
# Activer l'environnement
.venv\Scripts\activate

# Configurer la connexion : copier .env.example -> .env et remplir vos identifiants
copy .env.example .env
```

Les identifiants ClickHouse sont lus depuis des variables d'environnement dans `profiles.yml`
(`DBT_CH_HOST`, `DBT_CH_PORT`, `DBT_CH_USER`, `DBT_CH_PASSWORD`, `DBT_CH_SCHEMA`, `DBT_CH_SECURE`, `DBT_CH_DRIVER`) —
aucun secret n'est commité.

## Commandes

```powershell
$env:DBT_PROFILES_DIR = "."
.venv\Scripts\dbt.exe debug
.venv\Scripts\dbt.exe run
.venv\Scripts\dbt.exe test
```

## État d'avancement

- [x] Configuration initiale du projet dbt + connexion ClickHouse
- [x] Sources et modèles staging — Digital Gaming (37 modèles staging + data tests not_null/unique)
- [x] Sources et modèles staging — Digital Music (11 modèles staging + data tests not_null/unique)
- [ ] Sources et modèles staging — autres domaines (Digital Video, Physical Gaming/Music/Video,
      Group Procurement, IMDB, Market Intelligence, Seo Marketing, Support Reference)
- [x] Modèles intermediate — Digital Music (int_dm_tracks, int_dm_invoice_lines,
      int_dm_customer_activity, int_dm_playlists, int_dm_employees)
- [ ] Modèles intermediate — autres domaines
- [x] Modèles marts — Digital Music (core : DIM_ARTISTS/DIM_ALBUMS/DIM_TRACKS/DIM_CUSTOMERS/
      DIM_EMPLOYEES/DIM_PLAYLISTS/FTC_TRACK_SALES/FTC_PLAYLIST_TRACKS ; self_service :
      track_sales_analysis, monthly_revenue_trends, genre_revenue_trends,
      employee_sales_performance)
- [ ] Modèles marts — autres domaines (Digital Gaming : fichiers présents mais jamais exécutés,
      cf. absence de `+schema` sous `marts.DB_WH_Digital_gaming` dans dbt_project.yml)
