{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(plan_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = une formule d'abonnement. Catalogue statique (3 formules) -> dimension.
-- Complète FTC_SUBSCRIPTIONS (plan_name/plan_price/billing_period_days déjà dénormalisés dans le
-- fait pour le confort de lecture) en exposant le catalogue complet, y compris is_active
-- (formules retirées de la vente mais toujours référencées par d'anciens abonnements).

with subscription_plans as (
    select
        plan_id,
        name,
        price,
        billing_period_days,
        is_active
    from {{ ref('stg_dg_subscription_plans') }}
),

final as (
    select
        plan_id,
        name as plan_name,
        price,
        billing_period_days,
        is_active
    from subscription_plans
)

select
    plan_id,
    plan_name,
    price,
    billing_period_days,
    is_active
from final
