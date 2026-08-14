# dbt_clickhouse_project

Projet dbt Core connecté à ClickHouse.

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
