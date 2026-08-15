{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'achievements') }}
),

final as (
    select
        cast(id as bigint) as achievement_id,
        cast(game_id as bigint) as game_id,
        cast(name as String) as name,
        cast(description as String) as description,
        cast(icon_url as String) as icon_url,
        cast(points as int) as points
    from bases
)

select * from final
