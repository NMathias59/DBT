{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'chats') }}
),

final as (
    select
        cast(id as bigint) as chat_id,
        cast(name as String) as name,
        cast(created_at as datetime) as created_at
    from bases
)

select * from final
