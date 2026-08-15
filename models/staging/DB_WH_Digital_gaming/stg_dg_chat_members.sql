{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'chat_members') }}
),

final as (
    select  
        cast(chat_id as bigint) as chat_id,
        cast(user_id as bigint) as user_id,
        cast(joined_at as datetime) as joined_at
    from bases
)

select * from final