{{ config(
    materialized='view',
    tags=['intermediate', 'digital_video']
) }}

with ratings as (
    select * from {{ ref('stg_dv_rating') }}
),

movies as (
    select * from {{ ref('int_dv_movies') }}
),

final as (
    select
        ratings.user_id as user_id,
        ratings.movie_id as movie_id,
        movies.title as movie_title,
        movies.release_year as release_year,
        movies.genres_list as genres_list,
        ratings.rating as rating,
        -- Écart à la moyenne du film : positif = l'utilisateur a noté au-dessus de la moyenne
        -- reçue par le film, négatif = en dessous. Utile pour repérer des notes atypiques.
        round(ratings.rating - movies.avg_rating, 2) as rating_vs_movie_avg,
        ratings.rated_at as rated_at
    from ratings
    left join movies on ratings.movie_id = movies.movie_id
)

select * from final
