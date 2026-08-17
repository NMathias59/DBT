{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with fraud_flags as (
    select * from {{ ref('stg_dg_fraud_flags') }}
),

market_transactions as (
    select * from {{ ref('stg_dg_market_transactions') }}
),

market_listings as (
    select * from {{ ref('stg_dg_market_listings') }}
),

items as (
    select * from {{ ref('stg_dg_items') }}
),

-- toNullable(...) appliqué AVANT la jointure sur fraud_flags : un signalement de fraude n'est pas
-- toujours lié à une transaction de marché (ex: account_takeover_suspected). Sans ce cast explicite,
-- le LEFT JOIN renverrait la valeur par défaut du type (0 / '') pour ces lignes-là, au lieu de NULL.
market_context as (
    select
        market_transactions.market_transaction_id as market_transaction_id,
        toNullable(market_transactions.final_price) as related_transaction_amount,
        toNullable(items.name) as related_item_name
    from market_transactions
    left join market_listings on market_transactions.listing_id = market_listings.listing_id
    left join items on market_listings.item_id = items.item_id
),

final as (
    select
        fraud_flags.fraud_flag_id as fraud_flag_id,
        fraud_flags.user_id as user_id,
        fraud_flags.flagged_at as flagged_at,
        fraud_flags.flag_type as flag_type,
        fraud_flags.status as status,
        fraud_flags.related_market_transaction_id as related_market_transaction_id,
        market_context.related_transaction_amount as related_transaction_amount,
        market_context.related_item_name as related_item_name
    from fraud_flags
    left join market_context on fraud_flags.related_market_transaction_id = market_context.market_transaction_id
)

select * from final
