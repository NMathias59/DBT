{{ config(
    materialized='view',
    tags=['intermediate', 'imdb']
) }}

-- Grain: une ligne = une personne (cast/crew), avec sa filmographie agrégée tous rôles confondus.

with credits as (
    select * from {{ ref('stg_imdb_credit') }}
),

people as (
    select * from {{ ref('stg_imdb_person') }}
),

movies as (
    select * from {{ ref('stg_imdb_movie') }}
),

credits_with_year as (
    select
        credits.person_id as person_id,
        credits.movie_id as movie_id,
        credits.type as type,
        movies.year as year
    from credits
    left join movies on credits.movie_id = movies.movie_id
),

credits_agg as (
    select
        person_id,
        count() as total_credits,
        countIf(type = 'actor') as actor_credits,
        countIf(type = 'director') as director_credits,
        countIf(type = 'writer') as writer_credits,
        countIf(type = 'producer') as producer_credits,
        min(year) as first_credit_year,
        max(year) as last_credit_year
    from credits_with_year
    group by person_id
),

-- Note moyenne des films sur lesquels la personne a été créditée. distinct sur (person_id,
-- movie_id) car un même film peut donner lieu à plusieurs crédits pour la même personne (ex:
-- réalisateur ET scénariste du même film) -- sans ce distinct, ce film pèserait 2x dans la
-- moyenne.
distinct_movie_credits as (
    select distinct person_id, movie_id
    from credits
),

rating_agg as (
    select
        distinct_movie_credits.person_id as person_id,
        round(avg(movies.rating), 2) as avg_movie_rating
    from distinct_movie_credits
    left join movies on distinct_movie_credits.movie_id = movies.movie_id
    group by distinct_movie_credits.person_id
),

final as (
    select
        people.person_id as person_id,
        people.name as person_name,
        coalesce(credits_agg.total_credits, 0) as total_credits,
        coalesce(credits_agg.actor_credits, 0) as actor_credits,
        coalesce(credits_agg.director_credits, 0) as director_credits,
        coalesce(credits_agg.writer_credits, 0) as writer_credits,
        coalesce(credits_agg.producer_credits, 0) as producer_credits,
        credits_agg.first_credit_year as first_credit_year,
        credits_agg.last_credit_year as last_credit_year,
        rating_agg.avg_movie_rating as avg_movie_rating
    from people
    left join credits_agg on people.person_id = credits_agg.person_id
    left join rating_agg on people.person_id = rating_agg.person_id
)

select * from final
