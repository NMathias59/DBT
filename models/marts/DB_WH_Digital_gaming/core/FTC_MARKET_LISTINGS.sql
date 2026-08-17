{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(listed_at, listing_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = une annonce mise en vente sur le marché secondaire. Processus distinct de
-- FTC_MARKET_TRANSACTIONS (grain = transaction) : une annonce peut ne jamais se vendre, ou dans ce
-- jeu de données, être liée à plusieurs transactions -- utile pour du taux de conversion
-- (annonces vendues / total), temps moyen avant vente, backlog d'annonces non vendues.
--
-- is_sold vient de la source telle quelle ; is_sold_flag_consistent expose une incohérence
-- constatée dans les données (is_sold ne reflète pas toujours l'existence réelle d'une
-- transaction) plutôt que de la corriger silencieusement.
--
-- Table full rebuild (pas d'incrémental) : is_sold est mutable après listed_at.

with market_listings as (
    select * from {{ ref('int_dg_market_listings') }}
),

final as (
    select
        listing_id,
        seller_id,
        item_id,
        item_name,
        item_type,
        item_rarity,
        listed_price,
        listed_at,
        is_sold,
        transaction_count,
        is_sold_flag_consistent
    from market_listings
)

select * from final
