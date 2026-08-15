{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'chat_messages') }}
),

final as (
    select  
        cast(id as bigint) as message_id,
        cast(chat_id as bigint) as chat_id,
        cast(sender_id as bigint) as sender_id,
        cast(message as String) as message,
        cast(sent_at as datetime) as sent_at
    from bases
)

select * from final