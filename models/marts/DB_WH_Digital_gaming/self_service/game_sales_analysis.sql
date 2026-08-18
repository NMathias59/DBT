{{ config(
    materialized='view',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = une vente (jeu ou DLC), enrichie pour l'analyse métier sans jointure à faire
-- côté BI. Résout le jeu parent même pour une vente de DLC (via DIM_DLCS.game_id), pour pouvoir
-- toujours agréger par genre/éditeur/développeur quel que soit product_type.

with sales as (
    select
        sale_id,
        sale_at,
        sale_date,
        user_id,
        product_type,
        product_title,
        game_id,
        dlc_id,
        payment_provider,
        sale_amount
    from {{ ref('FTC_SALES') }}
),

games as (
    select
        game_id,
        title,
        publisher_name,
        developer_name,
        genre_names
    from {{ ref('DIM_GAMES') }}
),

dlcs as (
    select
        dlc_id,
        game_id
    from {{ ref('DIM_DLCS') }}
),

users as (
    select
        user_id,
        username
    from {{ ref('DIM_USERS') }}
),

dates as (
    select
        date_day,
        year,
        quarter,
        month,
        month_name,
        is_weekend
    from {{ ref('DIM_DATE') }}
),

sales_with_parent_game as (
    select
        sales.sale_id as sale_id,
        sales.sale_at as sale_at,
        sales.sale_date as sale_date,
        sales.user_id as user_id,
        sales.product_type as product_type,
        sales.product_title as product_title,
        sales.payment_provider as payment_provider,
        sales.sale_amount as sale_amount,
        coalesce(sales.game_id, dlcs.game_id) as resolved_game_id
    from sales
    left join dlcs on sales.dlc_id = dlcs.dlc_id
),

final as (
    select
        sales_with_parent_game.sale_id as sale_id,
        sales_with_parent_game.sale_at as sale_at,
        sales_with_parent_game.sale_date as sale_date,
        dates.year as sale_year,
        dates.quarter as sale_quarter,
        dates.month as sale_month,
        dates.month_name as sale_month_name,
        dates.is_weekend as sale_is_weekend,
        sales_with_parent_game.user_id as user_id,
        users.username as username,
        sales_with_parent_game.product_type as product_type,
        sales_with_parent_game.product_title as product_title,
        sales_with_parent_game.resolved_game_id as game_id,
        games.title as game_title,
        games.publisher_name as publisher_name,
        games.developer_name as developer_name,
        games.genre_names as genre_names,
        sales_with_parent_game.payment_provider as payment_provider,
        sales_with_parent_game.sale_amount as sale_amount
    from sales_with_parent_game
    left join games on sales_with_parent_game.resolved_game_id = games.game_id
    left join users on sales_with_parent_game.user_id = users.user_id
    left join dates on sales_with_parent_game.sale_date = dates.date_day
)

select
    sale_id,
    sale_at,
    sale_date,
    sale_year,
    sale_quarter,
    sale_month,
    sale_month_name,
    sale_is_weekend,
    user_id,
    username,
    product_type,
    product_title,
    game_id,
    game_title,
    publisher_name,
    developer_name,
    genre_names,
    payment_provider,
    sale_amount
from final
