{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(person_id)',
    tags=['marts', 'imdb', 'core']
) }}

-- Grain: une ligne = une personne (cast/crew), avec sa filmographie agrégée (int_imdb_people_
-- filmography). Full rebuild à chaque run, volume faible (catalogue statique).

with filmography as (
    select
        person_id,
        person_name,
        total_credits,
        actor_credits,
        director_credits,
        writer_credits,
        producer_credits,
        first_credit_year,
        last_credit_year,
        avg_movie_rating
    from {{ ref('int_imdb_people_filmography') }}
),

final as (
    select
        person_id,
        person_name,
        total_credits,
        actor_credits,
        director_credits,
        writer_credits,
        producer_credits,
        first_credit_year,
        last_credit_year,
        avg_movie_rating
    from filmography
)

select
    person_id,
    person_name,
    total_credits,
    actor_credits,
    director_credits,
    writer_credits,
    producer_credits,
    first_credit_year,
    last_credit_year,
    avg_movie_rating
from final
