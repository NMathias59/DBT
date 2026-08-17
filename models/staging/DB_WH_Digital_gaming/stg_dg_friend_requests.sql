{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'friend_requests') }}
),

final as (
    select
        cast(sender_id as bigint) as sender_id,
        cast(receiver_id as bigint) as receiver_id,
        cast(sent_at as datetime) as sent_at
    from bases
)

select * from final
