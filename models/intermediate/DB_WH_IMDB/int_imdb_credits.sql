{{ config(
    materialized='view',
    tags=['intermediate', 'imdb']
) }}

with credits as (
    select * from {{ ref('stg_imdb_credit') }}
),

movies as (
    select * from {{ ref('stg_imdb_movie') }}
),

people as (
    select * from {{ ref('stg_imdb_person') }}
),

final as (
    select
        credits.person_id as person_id,
        people.name as person_name,
        credits.movie_id as movie_id,
        movies.title as movie_title,
        movies.year as movie_year,
        movies.rating as movie_rating,
        credits.type as credit_type,
        credits.character as character,
        credits.note as note
    from credits
    left join movies on credits.movie_id = movies.movie_id
    left join people on credits.person_id = people.person_id
)

select * from final
