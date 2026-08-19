{{ config(
    materialized='view',
    tags=['self_service', 'imdb']
) }}

-- Grain: une ligne = un crédit, enrichi pour l'analyse métier sans jointure à faire côté BI :
-- genres/durée du film. Une ligne = un crédit (même grain que FTC_CREDITS).

with credits as (
    select
        credit_id,
        person_id,
        person_name,
        movie_id,
        movie_title,
        movie_year,
        credit_type,
        character
    from {{ ref('FTC_CREDITS') }}
),

movies as (
    select
        movie_id,
        rating,
        nvotes,
        running_time_minutes,
        genres_list
    from {{ ref('DIM_FILMS') }}
),

final as (
    select
        credits.credit_id as credit_id,
        credits.person_id as person_id,
        credits.person_name as person_name,
        credits.movie_id as movie_id,
        credits.movie_title as movie_title,
        credits.movie_year as movie_year,
        movies.rating as movie_rating,
        movies.nvotes as movie_nvotes,
        movies.running_time_minutes as movie_running_time_minutes,
        movies.genres_list as movie_genres,
        credits.credit_type as credit_type,
        credits.character as character
    from credits
    left join movies on credits.movie_id = movies.movie_id
)

select
    credit_id,
    person_id,
    person_name,
    movie_id,
    movie_title,
    movie_year,
    movie_rating,
    movie_nvotes,
    movie_running_time_minutes,
    movie_genres,
    credit_type,
    character
from final
