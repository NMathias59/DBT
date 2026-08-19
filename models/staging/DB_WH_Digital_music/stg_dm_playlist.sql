{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'playlist') }}
),

final as (
    select
        cast(playlist_id as bigint) as playlist_id,
        cast(name as Nullable(String)) as name
    from bases
)

select * from final
