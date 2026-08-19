{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'album') }}
),

final as (
    select
        cast(album_id as bigint) as album_id,
        cast(title as String) as title,
        cast(artist_id as bigint) as artist_id
    from bases
)

select * from final
