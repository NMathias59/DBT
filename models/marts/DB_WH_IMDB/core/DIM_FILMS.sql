{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(movie_id)',
    tags=['marts', 'imdb', 'core']
) }}

-- Grain: une ligne = un film du catalogue. Nommée DIM_FILMS (pas DIM_MOVIES, déjà pris par
-- Digital Video) pour éviter toute collision de nom de modèle dbt. Dimension type 1 (pas
-- d'historisation), full rebuild à chaque run, volume faible (catalogue statique). Genres/
-- langues/cast/crew déjà résolus et agrégés par int_imdb_movies.

with movies as (
    select
        movie_id,
        title,
        year,
        rating,
        nvotes,
        running_time_minutes,
        genres_list,
        genre_count,
        languages_list,
        director_names,
        writer_names,
        cast_names,
        director_count,
        writer_count,
        actor_count
    from {{ ref('int_imdb_movies') }}
),

final as (
    select
        movie_id,
        title,
        year,
        rating,
        nvotes,
        running_time_minutes,
        genres_list,
        genre_count,
        languages_list,
        director_names,
        writer_names,
        cast_names,
        director_count,
        writer_count,
        actor_count
    from movies
)

select
    movie_id,
    title,
    year,
    rating,
    nvotes,
    running_time_minutes,
    genres_list,
    genre_count,
    languages_list,
    director_names,
    writer_names,
    cast_names,
    director_count,
    writer_count,
    actor_count
from final
