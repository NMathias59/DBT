{{ config(
    materialized='view',
    tags=['intermediate', 'digital_video']
) }}

with movies as (
    select * from {{ ref('stg_dv_movie') }}
),

links as (
    select * from {{ ref('stg_dv_link') }}
),

ratings as (
    select * from {{ ref('stg_dv_rating') }}
),

tags as (
    select * from {{ ref('stg_dv_tag') }}
),

-- release_year : extrait du titre (ex: "Toy Story (1995)" -> 1995). extract() renvoie '' si le
-- titre ne se termine pas par "(YYYY)" (13/9742 titres sur ce jeu de données, ex: "Black Mirror",
-- titres de séries sans année) -- toInt32OrNull(...) bascule alors correctement sur NULL plutôt
-- que sur une valeur par défaut (0).
-- genres_list : "(no genres listed)" normalisé en tableau vide plutôt que gardé comme sentinelle
-- textuelle -- plus simple à consommer (empty()/arrayJoin) côté intermediate/marts.
movies_parsed as (
    select
        movie_id,
        title,
        genres,
        toInt32OrNull(extract(title, '\\((\\d{4})\\)$')) as release_year,
        if(genres = '(no genres listed)', [], splitByChar('|', genres)) as genres_list
    from movies
),

ratings_agg as (
    select
        movie_id,
        count() as rating_count,
        round(avg(rating), 2) as avg_rating
    from ratings
    group by movie_id
),

tags_agg as (
    select
        movie_id,
        count() as tag_count,
        groupUniqArray(tag) as tags_list
    from tags
    group by movie_id
),

final as (
    select
        movies_parsed.movie_id as movie_id,
        movies_parsed.title as title,
        movies_parsed.release_year as release_year,
        movies_parsed.genres_list as genres_list,
        length(movies_parsed.genres_list) as genre_count,
        links.imdb_id as imdb_id,
        links.tmdb_id as tmdb_id,
        ratings_agg.rating_count as rating_count,
        ratings_agg.avg_rating as avg_rating,
        tags_agg.tag_count as tag_count,
        tags_agg.tags_list as tags_list
    from movies_parsed
    left join links on movies_parsed.movie_id = links.movie_id
    left join ratings_agg on movies_parsed.movie_id = ratings_agg.movie_id
    left join tags_agg on movies_parsed.movie_id = tags_agg.movie_id
)

select * from final
