{% docs imdb_self_service_overview %}

## Self-service — IMDB

Couche de consommation pour les outils BI et les analystes métier, distincte de `core/` (le star
schema `FTC_*`/`DIM_*`, source de vérité technique).

### Règles de la couche

- **Un modèle = un usage métier documenté**, pas un mirroir 1:1 d'un fact/dim.
- **Nommage métier** en `snake_case` minuscule (ex: `movie_credits_analysis`), sans préfixe
  `FTC_`/`DIM_` — signale clairement "vue de consommation" vs "table du star schema".
- **Toujours via ref() sur les `FTC_*`/`DIM_*` de `core/`**, jamais de source() direct : le
  self-service ne doit jamais contourner le star schema ni sa logique déjà validée.
- **`view` par défaut** (config héritée de `dbt_project.yml`) : jointures/renommages sur des
  tables déjà matérialisées, coût quasi nul sur ClickHouse, toujours à jour. Passer un modèle en
  `table` uniquement s'il fait une vraie agrégation (`GROUP BY`) très consultée.
- **Schéma dédié** (`DB_WH_IMDB_REFERENCE_SELF_SERVICE`) pour pouvoir donner un accès en lecture
  aux outils BI sans exposer le schéma interne `DB_WH_IMDB_REFERENCE`.
- Documentés et testés comme le reste du projet (`data_tests` sur la clé de grain au minimum).
- **Grain annuel, pas mensuel** : contrairement aux autres domaines, ce référentiel n'a pas de
  date événementielle fine (voir imdb_overview) -- les tendances temporelles ici sont à l'année
  (`year`), pas au mois (`month_start`).

{% enddocs %}
