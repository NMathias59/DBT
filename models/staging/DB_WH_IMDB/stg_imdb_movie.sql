{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'movies') }}
),

final as (
    select
        cast(id as bigint) as movie_id,
        cast(title as String) as title,
        cast(year as Nullable(bigint)) as year,
        cast(rating as Nullable(Float64)) as rating,
        cast(nvotes as Nullable(bigint)) as nvotes
    from bases
)

select * from final
