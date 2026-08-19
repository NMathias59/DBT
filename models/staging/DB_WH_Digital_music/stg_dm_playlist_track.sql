{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'playlist_track') }}
),

final as (
    select
        cast(playlist_id as bigint) as playlist_id,
        cast(track_id as bigint) as track_id
    from bases
)

select * from final
