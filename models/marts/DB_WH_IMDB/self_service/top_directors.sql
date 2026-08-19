{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(person_id)',
    tags=['self_service', 'imdb']
) }}

-- Grain: une ligne = une personne créditée réalisateur d'au moins 2 films (seuil pour écarter le
-- bruit d'un unique film ponctuel). Photo d'ensemble, pas de tendance annuelle -- même logique de
-- grain que top_rated_movies côté Digital Video.
--
-- weighted_rating : moyenne pondérée façon IMDb (Bayesian average), même formule que
-- top_rated_movies -- pour ne pas laisser un réalisateur à 1 film noté 5.0 dominer un
-- réalisateur à 20 films notés 4.5. m (seuil) fixé à 3 films, plus bas que top_rated_movies
-- (m=20) car la filmographie d'un réalisateur est par nature bien plus restreinte que le nombre
-- de notes d'un film.

with credits as (
    select
        person_id,
        movie_id,
        credit_type
    from {{ ref('FTC_CREDITS') }}
    where credit_type = 'director'
),

people as (
    select
        person_id,
        person_name
    from {{ ref('DIM_PEOPLE') }}
),

movies as (
    select
        movie_id,
        rating,
        nvotes
    from {{ ref('DIM_FILMS') }}
),

director_movies as (
    select
        credits.person_id as person_id,
        credits.movie_id as movie_id,
        movies.rating as rating
    from credits
    left join movies on credits.movie_id = movies.movie_id
),

director_agg as (
    select
        person_id,
        count() as movies_directed,
        round(avg(rating), 3) as avg_rating
    from director_movies
    group by person_id
    having count() >= 2
),

global_avg as (
    select round(avg(avg_rating), 4) as global_avg_rating
    from director_agg
),

final as (
    select
        director_agg.person_id as person_id,
        people.person_name as person_name,
        director_agg.movies_directed as movies_directed,
        director_agg.avg_rating as avg_rating,
        round(
            (director_agg.movies_directed / (director_agg.movies_directed + 3.0)) * director_agg.avg_rating
            + (3.0 / (director_agg.movies_directed + 3.0)) * global_avg.global_avg_rating,
            3
        ) as weighted_rating
    from director_agg
    left join people on director_agg.person_id = people.person_id
    cross join global_avg
)

select
    person_id,
    person_name,
    movies_directed,
    avg_rating,
    weighted_rating
from final
