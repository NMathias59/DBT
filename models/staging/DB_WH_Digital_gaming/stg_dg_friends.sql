{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'friends') }}
),

final as (
    select
        cast(user_id as bigint) as user_id,
        cast(friend_id as bigint) as friend_id,
        cast(established_at as datetime) as established_at
    from bases
)

select * from final
