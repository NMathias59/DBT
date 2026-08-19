{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'media_type') }}
),

final as (
    select
        cast(media_type_id as bigint) as media_type_id,
        cast(name as Nullable(String)) as name
    from bases
)

select * from final
