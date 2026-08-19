{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(tagged_at, tag_id)',
    tags=['marts', 'digital_video', 'core']
) }}

-- Grain: une ligne = un tag posé par un utilisateur sur un film. tag_id = clé de substitution
-- (hash de user_id/movie_id/tag, pas de clé source) -- le triplet est unique sur ce jeu de
-- données. Full rebuild (pas d'incrémental) : volume faible (3683 lignes), pas besoin.

with tags as (
    select
        user_id,
        movie_id,
        tag,
        tagged_at
    from {{ ref('stg_dv_tag') }}
),

final as (
    select
        cityHash64(user_id, movie_id, tag) as tag_id,
        user_id,
        movie_id,
        tag,
        tagged_at
    from tags
)

select
    tag_id,
    user_id,
    movie_id,
    tag,
    tagged_at
from final
