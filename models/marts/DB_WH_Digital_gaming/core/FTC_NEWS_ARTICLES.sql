{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(published_at, article_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un article publié sur un jeu. Factless fact (pas de mesure numérique) :
-- utile pour corréler dans le temps avec FTC_REVIEWS (ex: chute de sentiment après un article/patch
-- note) ou FTC_SALES (pic de ventes après une annonce), même logique que nearest_prior_dlc_id
-- sur FTC_REVIEWS.
--
-- Table full rebuild, pas d'intermediate (pas de jointure/agrégation nécessaire), volume faible
-- et contenu immuable une fois publié.

with news_articles as (
    select * from {{ ref('stg_dg_news_articles') }}
),

final as (
    select
        article_id,
        game_id,
        title,
        published_at
    from news_articles
)

select * from final
