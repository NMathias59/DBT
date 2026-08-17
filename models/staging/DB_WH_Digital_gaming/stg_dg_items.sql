{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'items') }}
),

final as (
    select
        cast(id as bigint) as item_id,
        cast(game_id as bigint) as game_id,
        cast(name as String) as name,
        cast(description as String) as description,
        cast(type as String) as type,
        cast(rarity as String) as rarity
    from bases
)

select * from final
