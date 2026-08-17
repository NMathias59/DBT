{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'login_events') }}
),

final as (
    select
        cast(id as bigint) as login_event_id,
        cast(user_id as bigint) as user_id,
        cast(event_time as datetime) as event_time,
        cast(ip_address as String) as ip_address,
        cast(device as String) as device,
        cast(event_type as String) as event_type,
        cast(is_suspicious as bool) as is_suspicious
    from bases
)

select * from final
