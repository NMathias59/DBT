{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'group_members') }}
),

final as (
    select
        cast(group_id as bigint) as group_id,
        cast(user_id as bigint) as user_id,
        cast(joined_at as datetime) as joined_at
    from bases
)

select * from final
