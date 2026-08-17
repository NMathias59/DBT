{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(start_date, subscription_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un abonnement souscrit. plan_price = mesure (contribution MRR/ARR potentielle).
--
-- Table full rebuild (PAS d'incrémental) : comme pour FTC_REVIEWS, status / end_date / auto_renew
-- sont mutables après start_date (un abonnement passe de active à expired/cancelled plus tard,
-- peut se renouveler...). Un filtre incrémental sur start_date laisserait ces colonnes figées au
-- moment de la souscription. Volume faible (~300 abonnements), rebuild complet largement suffisant.

with subscriptions as (
    select * from {{ ref('int_dg_subscriptions') }}
),

final as (
    select
        subscription_id,
        user_id,
        plan_id,
        plan_name,
        plan_price,
        billing_period_days,
        start_date,
        end_date,
        status,
        auto_renew
    from subscriptions
)

select * from final
