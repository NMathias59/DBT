{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(game_id)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = un jeu. Funnel wishlist -> achat : parmi les utilisateurs ayant mis le jeu en
-- liste de souhaits, quelle part l'a effectivement acheté ensuite, et en combien de jours en
-- moyenne.
--
-- "Conversion" = premier achat du jeu (product_type='game') survenu À PARTIR de la date de premier
-- ajout en wishlist (pas avant -- un achat antérieur à la wishlist n'est pas une conversion causée
-- par la wishlist, ex: rachat, ou ajout après coup pour une raison X).
--
-- Grain par jeu (pas de tendance mensuelle ici) : un funnel se lit normalement comme une photo
-- d'ensemble, pas un historique -- si besoin d'un axe temporel (cohortes par mois d'ajout en
-- wishlist), ce serait un modèle séparé.

with wishlists as (
    select
        game_id,
        user_id,
        added_at
    from {{ ref('FTC_WISHLISTS') }}
),

sales as (
    select
        game_id,
        product_type,
        user_id,
        sale_at
    from {{ ref('FTC_SALES') }}
),

games as (
    select
        game_id,
        title,
        publisher_name
    from {{ ref('DIM_GAMES') }}
),

-- Premier ajout en wishlist par (jeu, utilisateur) -- un même couple peut apparaître plusieurs
-- fois dans FTC_WISHLISTS (ré-ajout), on ne garde que le tout premier.
wishlist_first as (
    select
        game_id,
        user_id,
        min(added_at) as first_wishlisted_at
    from wishlists
    group by game_id, user_id
),

-- Premier achat du jeu de base par (jeu, utilisateur). assumeNotNull(...) : FTC_SALES.game_id est
-- Nullable (NULL sur les ventes de DLC), mais filtré ici à product_type='game' où il n'est jamais
-- NULL -- sans ce cast, le type Nullable se propage jusqu'au ORDER BY final.
game_purchases_first as (
    select
        assumeNotNull(game_id) as game_id,
        user_id,
        min(sale_at) as first_purchased_at
    from sales
    where product_type = 'game'
    group by game_id, user_id
),

conversion as (
    select
        wishlist_first.game_id as game_id,
        wishlist_first.user_id as user_id,
        wishlist_first.first_wishlisted_at as first_wishlisted_at,
        game_purchases_first.first_purchased_at as first_purchased_at,
        (
            game_purchases_first.first_purchased_at is not null
            and game_purchases_first.first_purchased_at >= wishlist_first.first_wishlisted_at
        ) as converted
    from wishlist_first
    left join game_purchases_first
        on wishlist_first.game_id = game_purchases_first.game_id
        and wishlist_first.user_id = game_purchases_first.user_id
),

agg as (
    select
        game_id,
        count() as total_wishlisted_users,
        countIf(converted) as total_converted_users,
        round(countIf(converted) / count() * 100, 2) as conversion_rate_pct,
        -- avgIf(...) sur un ensemble vide (aucune conversion) renvoie NaN en ClickHouse, pas NULL
        -- -- garde explicite pour éviter d'exposer un NaN incohérent avec le reste du modèle.
        if(
            countIf(converted) = 0,
            NULL,
            round(avgIf(dateDiff('day', first_wishlisted_at, first_purchased_at), converted), 1)
        ) as avg_days_to_conversion
    from conversion
    group by game_id
),

final as (
    select
        agg.game_id as game_id,
        games.title as game_title,
        games.publisher_name as publisher_name,
        agg.total_wishlisted_users as total_wishlisted_users,
        agg.total_converted_users as total_converted_users,
        agg.conversion_rate_pct as conversion_rate_pct,
        agg.avg_days_to_conversion as avg_days_to_conversion
    from agg
    left join games on agg.game_id = games.game_id
)

select
    game_id,
    game_title,
    publisher_name,
    total_wishlisted_users,
    total_converted_users,
    conversion_rate_pct,
    avg_days_to_conversion
from final
