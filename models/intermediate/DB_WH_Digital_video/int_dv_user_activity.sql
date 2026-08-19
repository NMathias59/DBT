{{ config(
    materialized='view',
    tags=['intermediate', 'digital_video']
) }}

-- Pas de table utilisateur source dans ce domaine (contrairement à Digital Gaming/Music) --
-- voir dv_overview. La dimension utilisateur est entièrement DÉRIVÉE : la liste des user_id
-- vient de l'union des userId distincts de ratings/tags (610 dans ratings, 58 dans tags, tous
-- inclus dans ratings sur ce jeu de données -- l'union couvre le cas général où ce ne serait pas
-- toujours vrai).

with ratings as (
    select * from {{ ref('stg_dv_rating') }}
),

tags as (
    select * from {{ ref('stg_dv_tag') }}
),

user_ids as (
    select user_id from ratings
    union distinct
    select user_id from tags
),

ratings_agg as (
    select
        user_id,
        count() as ratings_count,
        round(avg(rating), 2) as avg_rating_given,
        min(rated_at) as first_rated_at,
        max(rated_at) as last_rated_at
    from ratings
    group by user_id
),

tags_agg as (
    select
        user_id,
        count() as tags_count
    from tags
    group by user_id
),

final as (
    select
        user_ids.user_id as user_id,
        ratings_agg.ratings_count as ratings_count,
        ratings_agg.avg_rating_given as avg_rating_given,
        ratings_agg.first_rated_at as first_rated_at,
        ratings_agg.last_rated_at as last_rated_at,
        tags_agg.tags_count as tags_count
    from user_ids
    left join ratings_agg on user_ids.user_id = ratings_agg.user_id
    left join tags_agg on user_ids.user_id = tags_agg.user_id
)

select * from final
