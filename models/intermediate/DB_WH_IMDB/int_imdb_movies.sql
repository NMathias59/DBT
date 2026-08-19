{{ config(
    materialized='view',
    tags=['intermediate', 'imdb']
) }}

with movies as (
    select * from {{ ref('stg_imdb_movie') }}
),

running_times as (
    select * from {{ ref('stg_imdb_running_time') }}
),

genres as (
    select * from {{ ref('stg_imdb_genre') }}
),

languages as (
    select * from {{ ref('stg_imdb_language') }}
),

credits as (
    select * from {{ ref('stg_imdb_credit') }}
),

people as (
    select * from {{ ref('stg_imdb_person') }}
),

genres_agg as (
    select
        movie_id,
        groupArray(genre) as genres_list
    from genres
    group by movie_id
),

languages_agg as (
    select
        movie_id,
        groupUniqArray(language) as languages_list
    from languages
    group by movie_id
),

-- Crédits croisés avec le nom de la personne (people), agrégés par rôle. countIf()/groupArrayIf()
-- filtrent sur credits.type -- un même film peut avoir plusieurs personnes pour un même rôle
-- (ex: co-réalisation), d'où des tableaux plutôt qu'une seule valeur.
credits_named as (
    select
        credits.movie_id as movie_id,
        credits.type as type,
        people.name as person_name
    from credits
    left join people on credits.person_id = people.person_id
),

credits_agg as (
    select
        movie_id,
        groupArrayIf(person_name, type = 'director') as director_names,
        groupArrayIf(person_name, type = 'writer') as writer_names,
        groupArrayIf(person_name, type = 'actor') as cast_names,
        countIf(type = 'director') as director_count,
        countIf(type = 'writer') as writer_count,
        countIf(type = 'actor') as actor_count
    from credits_named
    group by movie_id
),

final as (
    select
        movies.movie_id as movie_id,
        movies.title as title,
        movies.year as year,
        movies.rating as rating,
        movies.nvotes as nvotes,
        running_times.running_time_minutes as running_time_minutes,
        coalesce(genres_agg.genres_list, []) as genres_list,
        length(coalesce(genres_agg.genres_list, [])) as genre_count,
        coalesce(languages_agg.languages_list, []) as languages_list,
        coalesce(credits_agg.director_names, []) as director_names,
        coalesce(credits_agg.writer_names, []) as writer_names,
        coalesce(credits_agg.cast_names, []) as cast_names,
        coalesce(credits_agg.director_count, 0) as director_count,
        coalesce(credits_agg.writer_count, 0) as writer_count,
        coalesce(credits_agg.actor_count, 0) as actor_count
    from movies
    left join running_times on movies.movie_id = running_times.movie_id
    left join genres_agg on movies.movie_id = genres_agg.movie_id
    left join languages_agg on movies.movie_id = languages_agg.movie_id
    left join credits_agg on movies.movie_id = credits_agg.movie_id
)

select * from final
