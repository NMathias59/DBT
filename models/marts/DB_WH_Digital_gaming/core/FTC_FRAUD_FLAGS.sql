{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(flagged_at, fraud_flag_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un signalement de fraude. Table full rebuild (pas d'incrémental) : status
-- évolue après flagged_at au fil de l'investigation (open -> resolved/confirmed/dismissed...),
-- même piège que FTC_REVIEWS/FTC_SUBSCRIPTIONS. Volume très faible (~25 lignes), rebuild trivial.
--
-- related_transaction_amount / related_item_name : contexte de la transaction de marché liée,
-- quand le signalement en découle (ex: market_price_manipulation_suspected). NULL sinon
-- (ex: account_takeover_suspected, sans lien avec une transaction).

with fraud_flags as (
    select
        fraud_flag_id,
        user_id,
        flagged_at,
        flag_type,
        status,
        related_market_transaction_id,
        related_transaction_amount,
        related_item_name
    from {{ ref('int_dg_fraud_flags') }}
),

final as (
    select
        fraud_flag_id,
        user_id,
        flagged_at,
        flag_type,
        status,
        related_market_transaction_id,
        related_transaction_amount,
        related_item_name
    from fraud_flags
)

select
    fraud_flag_id,
    user_id,
    flagged_at,
    flag_type,
    status,
    related_market_transaction_id,
    related_transaction_amount,
    related_item_name
from final
