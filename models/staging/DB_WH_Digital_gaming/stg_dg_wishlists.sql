{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'wishlists') }}
),

final as (
    select
        cast(user_id as bigint) as user_id,
        cast(game_id as bigint) as game_id,
        cast(added_at as datetime) as added_at
    from bases
)

select * from final
