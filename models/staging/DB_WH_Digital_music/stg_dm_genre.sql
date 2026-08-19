{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'genre') }}
),

final as (
    select
        cast(genre_id as bigint) as genre_id,
        cast(name as Nullable(String)) as name
    from bases
)

select * from final
