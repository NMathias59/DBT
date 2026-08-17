{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'libraries') }}
),

final as (
    select
        cast(id as bigint) as library_id,
        cast(user_id as bigint) as user_id,
        cast(game_id as bigint) as game_id,
        cast(purchase_date as datetime) as purchase_date,
        cast(playtime_minutes as bigint) as playtime_minutes
    from bases
)

select * from final
