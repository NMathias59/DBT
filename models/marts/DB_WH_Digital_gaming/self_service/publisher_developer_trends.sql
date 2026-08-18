{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(entity_type, entity_name, month_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (entity_type ['publisher'|'developer'], entity_name, mois). Même logique que
-- genre_popularity_trends, mais sans le piège du multi-valué : un jeu a exactement un éditeur et
-- un développeur, donc pas de double comptage -- la somme des revenue_share_pct de tous les
-- publishers (ou de tous les developers) sur un même mois fait exactement 100%.
--
-- revenue_share_pct_change_mom : positif = éditeur/développeur qui gagne en part de marché,
-- négatif = qui en perd. NULL au premier mois disponible pour cette entité.

with sales as (
    select
        sale_date,
        game_id,
        dlc_id,
        sale_amount
    from {{ ref('FTC_SALES') }}
),

dlcs as (
    select
        dlc_id,
        game_id
    from {{ ref('DIM_DLCS') }}
),

games as (
    select
        game_id,
        publisher_name,
        developer_name
    from {{ ref('DIM_GAMES') }}
),

sales_with_parent_game as (
    select
        sales.sale_date as sale_date,
        sales.sale_amount as sale_amount,
        coalesce(sales.game_id, dlcs.game_id) as game_id
    from sales
    left join dlcs on sales.dlc_id = dlcs.dlc_id
),

monthly_market_total as (
    select
        toStartOfMonth(sale_date) as month_start,
        sum(sale_amount) as total_revenue_usd
    from sales_with_parent_game
    group by month_start
),

sales_with_entities as (
    select
        sales_with_parent_game.sale_date as sale_date,
        sales_with_parent_game.sale_amount as sale_amount,
        sales_with_parent_game.game_id as game_id,
        games.publisher_name as publisher_name,
        games.developer_name as developer_name
    from sales_with_parent_game
    left join games on sales_with_parent_game.game_id = games.game_id
),

publisher_agg as (
    select
        'publisher' as entity_type,
        publisher_name as entity_name,
        toStartOfMonth(sale_date) as month_start,
        sum(sale_amount) as revenue_usd,
        count() as units_sold,
        count(distinct game_id) as distinct_games_sold
    from sales_with_entities
    group by entity_type, entity_name, month_start
),

developer_agg as (
    select
        'developer' as entity_type,
        developer_name as entity_name,
        toStartOfMonth(sale_date) as month_start,
        sum(sale_amount) as revenue_usd,
        count() as units_sold,
        count(distinct game_id) as distinct_games_sold
    from sales_with_entities
    group by entity_type, entity_name, month_start
),

combined as (
    select * from publisher_agg
    union all
    select * from developer_agg
),

with_share as (
    select
        combined.entity_type as entity_type,
        combined.entity_name as entity_name,
        combined.month_start as month_start,
        combined.revenue_usd as revenue_usd,
        combined.units_sold as units_sold,
        combined.distinct_games_sold as distinct_games_sold,
        monthly_market_total.total_revenue_usd as total_revenue_usd,
        -- toFloat64(...) : même piège que genre_popularity_trends (division Decimal/Decimal
        -- tronquée à 2 décimales avant le *100).
        round(toFloat64(combined.revenue_usd) / toFloat64(monthly_market_total.total_revenue_usd) * 100, 2) as revenue_share_pct
    from combined
    left join monthly_market_total on combined.month_start = monthly_market_total.month_start
),

final as (
    select
        cityHash64(entity_type, entity_name, month_start) as row_id,
        entity_type,
        entity_name,
        month_start,
        toYear(month_start) as year,
        toMonth(month_start) as month_num,
        revenue_usd,
        units_sold,
        distinct_games_sold,
        total_revenue_usd,
        revenue_share_pct,
        -- toNullable(...) : lagInFrame renvoie 0 (pas NULL) au premier mois d'une entité faute de
        -- ligne précédente -- même piège que genre_popularity_trends.
        lagInFrame(toNullable(revenue_share_pct)) over (
            partition by entity_type, entity_name order by month_start
        ) as revenue_share_pct_prior_month,
        revenue_share_pct - lagInFrame(toNullable(revenue_share_pct)) over (
            partition by entity_type, entity_name order by month_start
        ) as revenue_share_pct_change_mom
    from with_share
)

select
    row_id,
    entity_type,
    entity_name,
    month_start,
    year,
    month_num,
    revenue_usd,
    units_sold,
    distinct_games_sold,
    total_revenue_usd,
    revenue_share_pct,
    revenue_share_pct_prior_month,
    revenue_share_pct_change_mom
from final
