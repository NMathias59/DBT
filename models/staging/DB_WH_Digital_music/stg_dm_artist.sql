{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'artist') }}
),

final as (
    select
        cast(artist_id as bigint) as artist_id,
        cast(name as Nullable(String)) as name
    from bases
)

select * from final
