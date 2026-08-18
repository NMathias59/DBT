{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with market_listings as (
    select * from {{ ref('stg_dg_market_listings') }}
),

market_transactions as (
    select * from {{ ref('stg_dg_market_transactions') }}
),

items as (
    select * from {{ ref('stg_dg_items') }}
),

-- count() sur un LEFT JOIN non matché renvoie naturellement 0 (pas de piège Nullable ici, 0 est
-- la valeur correcte pour "aucune transaction liée à ce listing").
txn_agg as (
    select
        listing_id,
        count() as transaction_count
    from market_transactions
    group by listing_id
),

final as (
    select
        market_listings.listing_id as listing_id,
        market_listings.seller_id as seller_id,
        market_listings.item_id as item_id,
        items.name as item_name,
        items.type as item_type,
        items.rarity as item_rarity,
        market_listings.price as listed_price,
        market_listings.listed_at as listed_at,
        market_listings.is_sold as is_sold_source_flag,
        txn_agg.transaction_count as transaction_count,
        -- Source de vérité recommandée : is_sold_source_flag n'est fiable que dans 49% des cas
        -- (constaté sur les données réelles, cf. is_sold_flag_consistent). Utiliser
        -- is_actually_sold pour toute analyse -- dérivé de l'existence réelle d'une transaction,
        -- pas du flag déclaratif de la source.
        txn_agg.transaction_count > 0 as is_actually_sold,
        market_listings.is_sold = (txn_agg.transaction_count > 0) as is_sold_flag_consistent
    from market_listings
    left join items on market_listings.item_id = items.item_id
    left join txn_agg on market_listings.listing_id = txn_agg.listing_id
)

select * from final
