{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with market_transactions as (
    select * from {{ ref('stg_dg_market_transactions') }}
),

market_listings as (
    select * from {{ ref('stg_dg_market_listings') }}
),

items as (
    select * from {{ ref('stg_dg_items') }}
),

final as (
    select
        market_transactions.market_transaction_id as market_transaction_id,
        market_transactions.listing_id as listing_id,
        market_listings.seller_id as seller_id,
        market_transactions.buyer_id as buyer_id,
        market_listings.item_id as item_id,
        items.name as item_name,
        items.type as item_type,
        items.rarity as item_rarity,
        market_listings.price as listed_price,
        market_transactions.final_price as final_price,
        market_transactions.final_price - market_listings.price as price_variance,
        market_listings.listed_at as listed_at,
        market_transactions.sold_at as sold_at
    from market_transactions
    left join market_listings on market_transactions.listing_id = market_listings.listing_id
    left join items on market_listings.item_id = items.item_id
)

select * from final
