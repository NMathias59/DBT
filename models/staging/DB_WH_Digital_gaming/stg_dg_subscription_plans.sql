{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'subscription_plans') }}
),

final as (
    select
        cast(id as bigint) as plan_id,
        cast(name as String) as name,
        cast(price as decimal(10, 2)) as price,
        cast(billing_period_days as int) as billing_period_days,
        cast(is_active as bool) as is_active
    from bases
)

select * from final
