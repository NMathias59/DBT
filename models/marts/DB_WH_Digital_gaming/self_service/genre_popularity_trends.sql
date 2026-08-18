{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(genre, month_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (genre, mois). Tendance de popularité des types de jeux dans le temps :
-- revenu, nombre de ventes, nombre de jeux distincts vendus, part de marché du genre ce mois-là,
-- et variation de cette part vs le mois précédent (positif = genre qui gagne en popularité,
-- négatif = qui en perd).
--
-- ATTENTION genre multi-valué : un jeu multi-genre compte dans chacun de ses genres (revenue_usd/
-- units_sold sont dupliqués entre ses genres). revenue_share_pct est calculé contre le VRAI total
-- du marché ce mois-là (total_revenue_usd_all_genres, sans double comptage) donc reste comparable
-- dans le temps, mais la somme des parts de tous les genres peut dépasser 100% à cause des jeux
-- multi-genres -- normal, pas un bug.
--
-- ATTENTION couverture mensuelle : pas de grille zero-fill ici (contrairement à
-- game_sales_monthly_revenue) -- constaté sur les données réelles que chaque genre a des ventes
-- quasi tous les mois (49-50 mois sur 50). Si un genre venait à avoir de vrais trous, la variation
-- mois-vs-mois (LAG) sauterait silencieusement au mois disponible précédent plutôt que de comparer
-- à un mois manquant à zéro -- acceptable ici, à revoir si la donnée devient plus creuse.

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
        genre_names
    from {{ ref('DIM_GAMES') }}
),

-- game_id est NULL sur une vente de DLC -- même résolution du jeu parent que game_sales_analysis
-- et game_sales_monthly_revenue.
sales_with_parent_game as (
    select
        sales.sale_date as sale_date,
        sales.sale_amount as sale_amount,
        coalesce(sales.game_id, dlcs.game_id) as game_id
    from sales
    left join dlcs on sales.dlc_id = dlcs.dlc_id
),

-- Vrai total du marché par mois, AVANT éclatement par genre -- sert de dénominateur pour
-- revenue_share_pct, sans double comptage des jeux multi-genres.
monthly_market_total as (
    select
        toStartOfMonth(sale_date) as month_start,
        sum(sale_amount) as total_revenue_usd_all_genres
    from sales_with_parent_game
    group by month_start
),

sales_with_genre as (
    select
        sales_with_parent_game.sale_date as sale_date,
        sales_with_parent_game.sale_amount as sale_amount,
        sales_with_parent_game.game_id as game_id,
        arrayJoin(games.genre_names) as genre
    from sales_with_parent_game
    left join games on sales_with_parent_game.game_id = games.game_id
),

monthly_genre_agg as (
    select
        toStartOfMonth(sale_date) as month_start,
        genre,
        sum(sale_amount) as revenue_usd,
        count() as units_sold,
        count(distinct game_id) as distinct_games_sold
    from sales_with_genre
    group by month_start, genre
),

with_share as (
    select
        monthly_genre_agg.genre as genre,
        monthly_genre_agg.month_start as month_start,
        monthly_genre_agg.revenue_usd as revenue_usd,
        monthly_genre_agg.units_sold as units_sold,
        monthly_genre_agg.distinct_games_sold as distinct_games_sold,
        monthly_market_total.total_revenue_usd_all_genres as total_revenue_usd_all_genres,
        -- toFloat64(...) : diviser deux Decimal(38,2) en ClickHouse tronque le quotient à 2
        -- décimales AVANT le *100 (ex: 79.98/764.53 -> 0.10 -> *100 = 10 au lieu de 10.46) --
        -- cast en Float64 pour une vraie division avant d'arrondir au final.
        round(toFloat64(monthly_genre_agg.revenue_usd) / toFloat64(monthly_market_total.total_revenue_usd_all_genres) * 100, 2) as revenue_share_pct
    from monthly_genre_agg
    left join monthly_market_total on monthly_genre_agg.month_start = monthly_market_total.month_start
),

final as (
    select
        cityHash64(genre, month_start) as row_id,
        genre,
        month_start,
        toYear(month_start) as year,
        toMonth(month_start) as month_num,
        revenue_usd,
        units_sold,
        distinct_games_sold,
        total_revenue_usd_all_genres,
        revenue_share_pct,
        -- toNullable(...) : lagInFrame renvoie 0 (pas NULL) au premier mois d'un genre faute de
        -- ligne précédente -- sans ce cast, on afficherait un faux "mois précédent à 0%" au lieu
        -- de "pas de mois précédent", ce qui gonflerait artificiellement revenue_share_pct_change_mom.
        lagInFrame(toNullable(revenue_share_pct)) over (
            partition by genre order by month_start
        ) as revenue_share_pct_prior_month,
        revenue_share_pct - lagInFrame(toNullable(revenue_share_pct)) over (
            partition by genre order by month_start
        ) as revenue_share_pct_change_mom
    from with_share
)

select
    row_id,
    genre,
    month_start,
    year,
    month_num,
    revenue_usd,
    units_sold,
    distinct_games_sold,
    total_revenue_usd_all_genres,
    revenue_share_pct,
    revenue_share_pct_prior_month,
    revenue_share_pct_change_mom
from final
