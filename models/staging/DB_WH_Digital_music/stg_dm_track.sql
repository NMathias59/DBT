{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'track') }}
),

final as (
    select
        cast(track_id as bigint) as track_id,
        cast(name as String) as name,
        cast(album_id as Nullable(bigint)) as album_id,
        cast(media_type_id as bigint) as media_type_id,
        cast(genre_id as Nullable(bigint)) as genre_id,
        cast(composer as Nullable(String)) as composer,
        cast(milliseconds as bigint) as milliseconds,
        cast(bytes as Nullable(bigint)) as bytes,
        cast(unit_price as decimal(10, 2)) as unit_price
    from bases
)

select * from final
