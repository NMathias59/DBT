{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'user_achievements') }}
),

final as (
    select
        cast(user_id as bigint) as user_id,
        cast(achievement_id as bigint) as achievement_id,
        cast(unlocked_at as datetime) as unlocked_at
    from bases
)

select * from final
