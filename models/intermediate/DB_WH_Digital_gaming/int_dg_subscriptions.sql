{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with subscriptions as (
    select * from {{ ref('stg_dg_subscriptions') }}
),

subscription_plans as (
    select * from {{ ref('stg_dg_subscription_plans') }}
),

final as (
    select
        subscriptions.subscription_id as subscription_id,
        subscriptions.user_id as user_id,
        subscriptions.plan_id as plan_id,
        subscription_plans.name as plan_name,
        subscription_plans.price as plan_price,
        subscription_plans.billing_period_days as billing_period_days,
        subscriptions.start_date as start_date,
        subscriptions.end_date as end_date,
        subscriptions.status as status,
        subscriptions.auto_renew as auto_renew
    from subscriptions
    left join subscription_plans on subscriptions.plan_id = subscription_plans.plan_id
)

select * from final
