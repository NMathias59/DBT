{{ config(
    materialized='view',
    tags=['self_service', 'digital_video']
) }}

-- Grain: une ligne = une note, enrichie pour l'analyse métier sans jointure à faire côté BI :
-- calendrier, film (titre/année/genres), écart à la moyenne du film. DIM_DATE réutilisée depuis
-- Digital Gaming (dimension générique, pas spécifique à un domaine).

with ratings as (
    select
        rating_id,
        user_id,
        movie_id,
        rating,
        rated_at,
        rated_date
    from {{ ref('FTC_RATINGS') }}
),

movies as (
    select
        movie_id,
        title,
        release_year,
        genres_list,
        avg_rating
    from {{ ref('DIM_MOVIES') }}
),

dates as (
    select
        date_day,
        year,
        quarter,
        month,
        month_name,
        is_weekend
    from {{ ref('DIM_DATE') }}
),

final as (
    select
        ratings.rating_id as rating_id,
        ratings.rated_at as rated_at,
        ratings.rated_date as rated_date,
        dates.year as rated_year,
        dates.quarter as rated_quarter,
        dates.month as rated_month,
        dates.month_name as rated_month_name,
        dates.is_weekend as rated_is_weekend,
        ratings.user_id as user_id,
        ratings.movie_id as movie_id,
        movies.title as movie_title,
        movies.release_year as movie_release_year,
        movies.genres_list as movie_genres,
        ratings.rating as rating,
        movies.avg_rating as movie_avg_rating,
        round(ratings.rating - movies.avg_rating, 2) as rating_vs_movie_avg
    from ratings
    left join movies on ratings.movie_id = movies.movie_id
    left join dates on ratings.rated_date = dates.date_day
)

select
    rating_id,
    rated_at,
    rated_date,
    rated_year,
    rated_quarter,
    rated_month,
    rated_month_name,
    rated_is_weekend,
    user_id,
    movie_id,
    movie_title,
    movie_release_year,
    movie_genres,
    rating,
    movie_avg_rating,
    rating_vs_movie_avg
from final
