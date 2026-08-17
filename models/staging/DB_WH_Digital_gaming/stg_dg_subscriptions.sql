{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'subscriptions') }}
),

final as (
    select
        cast(id as bigint) as subscription_id,
        cast(user_id as bigint) as user_id,
        cast(plan_id as bigint) as plan_id,
        cast(start_date as date) as start_date,
        cast(end_date as Nullable(date)) as end_date,
        cast(status as String) as status,
        cast(auto_renew as bool) as auto_renew
    from bases
)

select * from final
