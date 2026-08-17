{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with games as (
    select * from {{ ref('stg_dg_games') }}
),

developers as (
    select * from {{ ref('stg_dg_developers') }}
),

publishers as (
    select * from {{ ref('stg_dg_publishers') }}
),

game_genres as (
    select * from {{ ref('stg_dg_game_genres') }}
),

genres as (
    select * from {{ ref('stg_dg_genres') }}
),

game_tags as (
    select * from {{ ref('stg_dg_game_tags') }}
),

tags as (
    select * from {{ ref('stg_dg_tags') }}
),

system_requirements as (
    select * from {{ ref('stg_dg_system_requirements') }}
),

genres_agg as (
    select
        game_genres.game_id,
        groupArray(genres.genre_id) as genre_ids,
        groupArray(genres.name) as genre_names
    from game_genres
    left join genres on game_genres.genre_id = genres.genre_id
    group by game_genres.game_id
),

tags_agg as (
    select
        game_tags.game_id,
        groupArray(tags.tag_id) as tag_ids,
        groupArray(tags.name) as tag_names
    from game_tags
    left join tags on game_tags.tag_id = tags.tag_id
    group by game_tags.game_id
),

final as (
    select
        games.game_id as game_id,
        games.title,
        games.price,
        games.release_date,
        games.publisher_id as publisher_id,
        publishers.name as publisher_name,
        games.developer_id as developer_id,
        developers.name as developer_name,
        genres_agg.genre_ids,
        genres_agg.genre_names,
        tags_agg.tag_ids,
        tags_agg.tag_names,
        system_requirements.operating_system,
        system_requirements.processor,
        system_requirements.memory,
        system_requirements.graphics,
        system_requirements.storage
    from games
    left join publishers on games.publisher_id = publishers.publisher_id
    left join developers on games.developer_id = developers.developer_id
    left join genres_agg on games.game_id = genres_agg.game_id
    left join tags_agg on games.game_id = tags_agg.game_id
    left join system_requirements on games.game_id = system_requirements.game_id
)

select * from final
