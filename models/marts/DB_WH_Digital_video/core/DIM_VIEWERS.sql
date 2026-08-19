{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(user_id)',
    tags=['marts', 'digital_video', 'core']
) }}

-- Grain: une ligne = un utilisateur, avec ses agrégats d'activité (notes, tags). Nommée
-- DIM_VIEWERS (pas DIM_USERS, déjà pris par Digital Gaming) pour éviter toute collision de nom
-- de modèle dbt. Dimension entièrement DÉRIVÉE : pas de table utilisateur source dans ce domaine
-- -- voir le commentaire dans int_dv_user_activity. Full rebuild à chaque run, volume faible.

with user_activity as (
    select
        user_id,
        ratings_count,
        avg_rating_given,
        first_rated_at,
        last_rated_at,
        tags_count
    from {{ ref('int_dv_user_activity') }}
),

final as (
    select
        user_id,
        ratings_count,
        avg_rating_given,
        first_rated_at,
        last_rated_at,
        tags_count
    from user_activity
)

select
    user_id,
    ratings_count,
    avg_rating_given,
    first_rated_at,
    last_rated_at,
    tags_count
from final
