{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'reviews') }}
),

final as (
    select
        cast(id as bigint) as review_id,
        cast(user_id as bigint) as user_id,
        cast(game_id as bigint) as game_id,
        cast(content as String) as content,
        cast(is_recommended as bool) as is_recommended,
        cast(created_at as datetime) as created_at
    from bases
)

select * from final
