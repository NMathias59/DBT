{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'game_tags') }}
),

final as (
    select
        cast(game_id as bigint) as game_id,
        cast(tag_id as bigint) as tag_id
    from bases
)

select * from final
