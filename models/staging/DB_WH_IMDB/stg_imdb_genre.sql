{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'genres') }}
),

final as (
    select
        cast(movie_id as bigint) as movie_id,
        cast(genre as String) as genre
    from bases
)

select * from final
