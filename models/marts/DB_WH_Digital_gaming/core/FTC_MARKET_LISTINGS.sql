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
-- ATTENTION qualité de données : is_sold_source_flag (flag brut de la source) n'est fiable que
-- dans 49% des cas (constaté sur les 810 annonces réelles -- 416 incohérentes). Utiliser
-- is_actually_sold pour toute analyse : dérivé de l'existence réelle d'une transaction, pas du
-- flag déclaratif. is_sold_source_flag/is_sold_flag_consistent restent exposés pour traçabilité
-- et remontée du problème auprès de l'équipe qui gère l'ingestion DB_WH_DIGITAL_GAMING.
--
-- Table full rebuild (pas d'incrémental) : le statut est mutable après listed_at.

with market_listings as (
    select
        listing_id,
        seller_id,
        item_id,
        item_name,
        item_type,
        item_rarity,
        listed_price,
        listed_at,
        is_actually_sold,
        transaction_count,
        is_sold_source_flag,
        is_sold_flag_consistent
    from {{ ref('int_dg_market_listings') }}
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
        is_actually_sold,
        transaction_count,
        is_sold_source_flag,
        is_sold_flag_consistent
    from market_listings
)

select
    listing_id,
    seller_id,
    item_id,
    item_name,
    item_type,
    item_rarity,
    listed_price,
    listed_at,
    is_actually_sold,
    transaction_count,
    is_sold_source_flag,
    is_sold_flag_consistent
from final
