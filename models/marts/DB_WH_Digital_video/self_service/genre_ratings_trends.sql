{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(genre, month_start)',
    tags=['self_service', 'digital_video']
) }}

-- Grain: une ligne = (genre, month_start). Volume et note moyenne des évaluations par genre dans
-- le temps.
--
-- ATTENTION genre multi-valué : un film multi-genre compte dans chacun de ses genres (une note
-- sur un film "Adventure|Comedy" est comptée dans les deux) -- même logique que
-- genre_popularity_trends côté Digital Gaming. rating_share_pct (volume, pas note) peut donc
-- dépasser 100% en sommant tous les genres d'un même mois -- normal, pas un bug.

with ratings as (
    select
        movie_id,
        rating,
        rated_date
    from {{ ref('FTC_RATINGS') }}
),

movies as (
    select
        movie_id,
        genres_list
    from {{ ref('DIM_MOVIES') }}
),

-- arrayJoin explose une ligne par genre du film -- une note sur un film à 3 genres devient 3
-- lignes ici, une par genre. coalesce sur un tableau vide (genres_list = []) donnerait 0 ligne
-- (arrayJoin sur [] ne produit rien) -- normalisé en 'Unknown' pour ne pas perdre ces notes.
ratings_genre as (
    select
        toStartOfMonth(ratings.rated_date) as month_start,
        if(empty(movies.genres_list), 'Unknown', arrayJoin(movies.genres_list)) as genre,
        ratings.rating as rating
    from ratings
    left join movies on ratings.movie_id = movies.movie_id
),

monthly_genre_agg as (
    select
        genre,
        month_start,
        count() as rating_count,
        round(avg(rating), 2) as avg_rating
    from ratings_genre
    group by genre, month_start
),

monthly_total as (
    select
        month_start,
        count() as total_rating_count
    from ratings_genre
    group by month_start
),

combined as (
    select
        monthly_genre_agg.genre as genre,
        monthly_genre_agg.month_start as month_start,
        monthly_genre_agg.rating_count as rating_count,
        monthly_genre_agg.avg_rating as avg_rating,
        monthly_total.total_rating_count as total_rating_count,
        round(monthly_genre_agg.rating_count / monthly_total.total_rating_count * 100, 2) as rating_share_pct
    from monthly_genre_agg
    left join monthly_total on monthly_genre_agg.month_start = monthly_total.month_start
),

final as (
    select
        cityHash64(genre, month_start) as row_id,
        genre,
        month_start,
        toYear(month_start) as year,
        toMonth(month_start) as month_num,
        rating_count,
        avg_rating,
        total_rating_count,
        rating_share_pct
    from combined
)

select
    row_id,
    genre,
    month_start,
    year,
    month_num,
    rating_count,
    avg_rating,
    total_rating_count,
    rating_share_pct
from final
