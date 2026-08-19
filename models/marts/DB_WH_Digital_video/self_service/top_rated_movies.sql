{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(movie_id)',
    tags=['self_service', 'digital_video']
) }}

-- Grain: une ligne = un film ayant reçu au moins une note. Photo d'ensemble, pas de tendance
-- mensuelle -- même logique de grain que wishlist_conversion_funnel/dlc_attach_rate côté Digital
-- Gaming.
--
-- weighted_rating : moyenne pondérée façon IMDb (Bayesian average), pour ne pas laisser un film
-- à 1 note de 5.0 dominer un film à 500 notes de 4.5. Formule : (v/(v+m))*R + (m/(v+m))*C, où
-- v = rating_count du film, R = avg_rating du film, m = seuil minimum de notes (var codée en dur
-- à 20, proche du 1er quartile de rating_count sur ce jeu de données), C = note moyenne globale
-- tous films confondus.

with movies as (
    select
        movie_id,
        title,
        release_year,
        genres_list,
        rating_count,
        avg_rating
    from {{ ref('DIM_MOVIES') }}
    where rating_count > 0
),

global_avg as (
    select round(avg(avg_rating), 4) as global_avg_rating
    from movies
),

final as (
    select
        movies.movie_id as movie_id,
        movies.title as title,
        movies.release_year as release_year,
        movies.genres_list as genres,
        movies.rating_count as rating_count,
        movies.avg_rating as avg_rating,
        round(
            (movies.rating_count / (movies.rating_count + 20.0)) * movies.avg_rating
            + (20.0 / (movies.rating_count + 20.0)) * global_avg.global_avg_rating,
            3
        ) as weighted_rating
    from movies
    cross join global_avg
)

select
    movie_id,
    title,
    release_year,
    genres,
    rating_count,
    avg_rating,
    weighted_rating
from final
