{% docs dm_self_service_overview %}

## Self-service — Digital Music

Couche de consommation pour les outils BI et les analystes métier, distincte de `core/` (le star
schema `FTC_*`/`DIM_*`, source de vérité technique).

### Règles de la couche

- **Un modèle = un usage métier documenté**, pas un mirroir 1:1 d'un fact/dim.
- **Nommage métier** en `snake_case` minuscule (ex: `track_sales_analysis`), sans préfixe
  `FTC_`/`DIM_` — signale clairement "vue de consommation" vs "table du star schema".
- **Toujours via ref() sur les `FTC_*`/`DIM_*` de `core/`** (y compris `DIM_DATE`, réutilisée
  depuis Digital Gaming — dimension générique, pas spécifique à un domaine), jamais de source()
  direct : le self-service ne doit jamais contourner le star schema ni sa logique déjà validée.
- **`view` par défaut** (config héritée de `dbt_project.yml`) : jointures/renommages sur des
  tables déjà matérialisées, coût quasi nul sur ClickHouse, toujours à jour. Passer un modèle en
  `table` uniquement s'il fait une vraie agrégation (`GROUP BY`) très consultée.
- **Schéma dédié** (`DB_WH_DIGITAL_MUSIC_SELF_SERVICE`) pour pouvoir donner un accès en lecture
  aux outils BI sans exposer le schéma interne `DB_WH_DIGITAL_MUSIC`.
- Documentés et testés comme le reste du projet (`data_tests` sur la clé de grain au minimum).

{% enddocs %}
