{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(item_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un objet in-game (arme, cosmétique...) du catalogue. Catalogue statique
-- (pas d'horodatage ni de statut mutable en source) -> dimension, pas un fait. Complète
-- FTC_MARKET_LISTINGS/FTC_MARKET_TRANSACTIONS qui référencent item_id sans dimension dédiée
-- jusqu'ici (attributs dénormalisés directement dans ces facts pour le confort de lecture, cette
-- dim sert plutôt à parcourir/filtrer le catalogue complet, vendu ou non sur le marché).

with items as (
    select
        item_id,
        game_id,
        name,
        type,
        rarity
    from {{ ref('stg_dg_items') }}
),

games as (
    select
        game_id,
        title
    from {{ ref('stg_dg_games') }}
),

final as (
    select
        items.item_id as item_id,
        items.game_id as game_id,
        games.title as game_title,
        items.name as item_name,
        items.type as item_type,
        items.rarity as item_rarity
    from items
    left join games on items.game_id = games.game_id
)

select
    item_id,
    game_id,
    game_title,
    item_name,
    item_type,
    item_rarity
from final
