{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by='toYYYYMM(sale_date)',
    engine='MergeTree()',
    order_by='(sale_date, market_transaction_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = une transaction sur le marché secondaire (échange C2C d'un objet in-game).
-- Processus distinct de la vente primaire (FTC_SALES) : l'argent circule entre deux joueurs,
-- pas de revenu plateforme direct, prix négocié (listed_price vs final_price).
--
-- Incrémental insert_overwrite, partitionné par mois (toYYYYMM(sale_date)) : mêmes règles que
-- FTC_SALES -- on recharge les N derniers mois COMPLETS (var dg_incremental_lookback_months) puis
-- REPLACE PARTITION, jamais un filtre ">dernier timestamp" qui tronquerait la partition en place.

with market_transactions as (
    select * from {{ ref('int_dg_market_transactions') }}
    {% if is_incremental() %}
    where sold_at >= dateTrunc('month', now()) - interval {{ var('dg_incremental_lookback_months') }} month
    {% endif %}
),

final as (
    select
        market_transaction_id,
        listing_id,
        seller_id,
        buyer_id,
        item_id,
        item_name,
        item_type,
        item_rarity,
        listed_price,
        final_price,
        price_variance,
        listed_at,
        sold_at,
        toDate(sold_at) as sale_date
    from market_transactions
)

select * from final
