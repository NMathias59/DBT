{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(game_id, product_type, genre, sale_month)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (jeu, product_type, genre, mois). Pensé pour l'analyse de revenu long terme :
-- CA en USD, cumul à date en USD ET en CAD, 12 mois glissants en USD, filtrable par product_type
-- (game/dlc) et par genre.
--
-- CAD uniquement sur le cumul à date (cumulative_revenue_cad) -- pas sur le revenu mensuel brut ni
-- sur le 12 mois glissant, qui restent en USD.
--
-- ATTENTION conversion CAD : taux de change FIXE (var dg_usd_to_cad_rate, actuellement
-- {{ var('dg_usd_to_cad_rate') }}), pas de table de taux historique par période. Précision
-- suffisante pour une tendance, pas pour un reporting financier officiel -- à remplacer par une
-- vraie source de taux si besoin.
--
-- ATTENTION genre multi-valué : un jeu avec plusieurs genres apparaît une fois par genre (colonne
-- genre explosée depuis DIM_GAMES.genre_names). Filtrer sur UN SEUL genre à la fois donne un total
-- correct. Sommer sur plusieurs genres, ou ne pas filtrer du tout, SURCOMPTE les jeux multi-genres
-- (leur revenu est dupliqué dans chaque genre qu'ils couvrent).
--
-- ATTENTION grille mensuelle : cumulative_revenue_* et rolling_12m_revenue_* sont calculés sur une
-- grille mensuelle complète (mois sans vente = 0), PAS sur les seuls mois avec des ventes -- sinon
-- "12 mois glissants" compterait 12 lignes non-nulles au lieu de 12 mois calendaires, ce qui
-- fausserait le résultat pour un jeu aux ventes espacées. Les fenêtres sont calculées par
-- (game_id, product_type) AVANT l'éclatement par genre, donc elles restent additives correctement
-- si on somme plusieurs jeux d'un même genre (cf. avertissement genre ci-dessus, qui s'applique
-- seulement au sein d'un même jeu multi-genre).

with sales as (
    select
        sale_date,
        game_id,
        dlc_id,
        product_type,
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

-- game_id est NULL sur une vente de DLC (seul dlc_id est renseigné) -- on résout le jeu parent via
-- DIM_DLCS, même logique que game_sales_analysis, sinon tout le revenu DLC serait orphelin
-- (game_id NULL) et absent de ce dataset.
sales_with_parent_game as (
    select
        sales.sale_date as sale_date,
        sales.product_type as product_type,
        sales.sale_amount as sale_amount,
        coalesce(sales.game_id, dlcs.game_id) as game_id
    from sales
    left join dlcs on sales.dlc_id = dlcs.dlc_id
),

monthly_sales as (
    select
        toStartOfMonth(sale_date) as sale_month,
        game_id,
        product_type,
        sum(sale_amount) as revenue_usd
    from sales_with_parent_game
    group by sale_month, game_id, product_type
),

game_product_combos as (
    select
        game_id,
        product_type,
        min(sale_month) as first_month
    from monthly_sales
    group by game_id, product_type
),

bounds as (
    select max(sale_month) as global_max_month
    from monthly_sales
),

months_spine as (
    select distinct toStartOfMonth(date_day) as sale_month
    from {{ ref('DIM_DATE') }}
    where date_day = toStartOfMonth(date_day)
),

-- Grille mensuelle complète par (game_id, product_type), du premier mois de vente de ce couple
-- jusqu'au dernier mois connu tous jeux confondus -- pas de mois "fantômes" avant la sortie du jeu.
full_grid as (
    select
        game_product_combos.game_id as game_id,
        game_product_combos.product_type as product_type,
        months_spine.sale_month as sale_month
    from game_product_combos
    cross join months_spine
    cross join bounds
    where months_spine.sale_month >= game_product_combos.first_month
      and months_spine.sale_month <= bounds.global_max_month
),

full_grid_revenue as (
    select
        full_grid.game_id as game_id,
        full_grid.product_type as product_type,
        full_grid.sale_month as sale_month,
        coalesce(monthly_sales.revenue_usd, 0) as revenue_usd
    from full_grid
    left join monthly_sales
        on full_grid.game_id = monthly_sales.game_id
        and full_grid.product_type = monthly_sales.product_type
        and full_grid.sale_month = monthly_sales.sale_month
),

windowed as (
    select
        game_id,
        product_type,
        sale_month,
        revenue_usd,
        sum(revenue_usd) over (
            partition by game_id, product_type
            order by sale_month
            rows between unbounded preceding and current row
        ) as cumulative_revenue_usd,
        sum(revenue_usd) over (
            partition by game_id, product_type
            order by sale_month
            rows between 11 preceding and current row
        ) as rolling_12m_revenue_usd
    from full_grid_revenue
),

exploded_genres as (
    select
        windowed.game_id as game_id,
        windowed.product_type as product_type,
        windowed.sale_month as sale_month,
        windowed.revenue_usd as revenue_usd,
        windowed.cumulative_revenue_usd as cumulative_revenue_usd,
        windowed.rolling_12m_revenue_usd as rolling_12m_revenue_usd,
        games.title as game_title,
        games.publisher_name as publisher_name,
        games.developer_name as developer_name,
        arrayJoin(games.genre_names) as genre
    from windowed
    left join games on windowed.game_id = games.game_id
),

final as (
    select
        cityHash64(game_id, product_type, genre, sale_month) as row_id,
        game_id,
        game_title,
        product_type,
        genre,
        publisher_name,
        developer_name,
        sale_month,
        toYear(sale_month) as sale_year,
        toMonth(sale_month) as sale_month_num,
        revenue_usd,
        cumulative_revenue_usd,
        round(cumulative_revenue_usd * {{ var('dg_usd_to_cad_rate') }}, 2) as cumulative_revenue_cad,
        rolling_12m_revenue_usd
    from exploded_genres
)

select
    row_id,
    game_id,
    game_title,
    product_type,
    genre,
    publisher_name,
    developer_name,
    sale_month,
    sale_year,
    sale_month_num,
    revenue_usd,
    cumulative_revenue_usd,
    cumulative_revenue_cad,
    rolling_12m_revenue_usd
from final
