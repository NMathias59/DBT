{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(movie_id)',
    tags=['marts', 'digital_video', 'core']
) }}

-- Grain: une ligne = un film du catalogue. Dimension type 1 (pas d'historisation), full rebuild
-- à chaque run, volume faible (catalogue MovieLens). Genres éclatés en tableau, identifiants
-- externes (IMDb/TMDb) et agrégats de notes/tags déjà résolus par int_dv_movies.

with movies as (
    select
        movie_id,
        title,
        release_year,
        genres_list,
        genre_count,
        imdb_id,
        tmdb_id,
        rating_count,
        avg_rating,
        tag_count,
        tags_list
    from {{ ref('int_dv_movies') }}
),

final as (
    select
        movie_id,
        title,
        release_year,
        genres_list,
        genre_count,
        imdb_id,
        tmdb_id,
        rating_count,
        avg_rating,
        tag_count,
        tags_list
    from movies
)

select
    movie_id,
    title,
    release_year,
    genres_list,
    genre_count,
    imdb_id,
    tmdb_id,
    rating_count,
    avg_rating,
    tag_count,
    tags_list
from final
