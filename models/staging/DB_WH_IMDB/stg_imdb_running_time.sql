{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'running_times') }}
),

final as (
    select
        cast(movie_id as bigint) as movie_id,
        -- running_time : String en source, toujours numérique sur ce jeu de données (vérifié --
        -- pas de format "USA:118" ou similaire) -- casté directement en minutes.
        cast(running_time as bigint) as running_time_minutes,
        cast(note as Nullable(String)) as note
    from bases
)

select * from final
