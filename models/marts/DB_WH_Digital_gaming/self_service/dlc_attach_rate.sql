{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(game_id, month_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (jeu, mois), pour les jeux ayant au moins un DLC (113 jeux). attach_rate =
-- part des propriétaires du jeu de base qui possèdent aussi au moins un DLC de ce jeu, EN CUMUL
-- À DATE (pas seulement les acheteurs du mois) -- c'est la définition standard d'un "attach rate".
--
-- Un même utilisateur ne compte qu'une fois dans cumulative_owners/cumulative_dlc_owners même
-- s'il rachète plusieurs fois (compté à son premier achat), pour éviter de gonfler artificiellement
-- le taux avec des rachats.
--
-- Grille mensuelle par jeu (comme game_sales_monthly_revenue) : du premier mois où quelqu'un
-- possède le jeu jusqu'au dernier mois connu, mois sans nouvel acheteur = 0 nouveau propriétaire
-- ce mois-là (le cumul, lui, ne baisse jamais).

with sales as (
    select
        sale_date,
        game_id,
        dlc_id,
        product_type,
        user_id
    from {{ ref('FTC_SALES') }}
),

dlcs as (
    select
        dlc_id,
        game_id
    from {{ ref('DIM_DLCS') }}
),

games_with_dlcs as (
    select distinct game_id
    from dlcs
),

games as (
    select
        game_id,
        title,
        publisher_name
    from {{ ref('DIM_GAMES') }}
),

-- Premier mois où chaque utilisateur possède le jeu de base (un seul compte même en cas de rachat).
-- assumeNotNull(...) : FTC_SALES.game_id est typé Nullable (NULL sur les ventes de DLC), mais ici
-- filtré à product_type = 'game' où il n'est jamais NULL en pratique -- sans ce cast, le type
-- Nullable se propage jusqu'au ORDER BY final et ClickHouse refuse (allow_nullable_key désactivé).
game_first_purchase as (
    select
        assumeNotNull(game_id) as game_id,
        user_id,
        min(toStartOfMonth(sale_date)) as first_owned_month
    from sales
    where product_type = 'game'
    group by game_id, user_id
),

-- Premier mois où chaque utilisateur possède un DLC de ce jeu (n'importe lequel des DLC du jeu).
dlc_first_purchase as (
    select
        dlcs.game_id as game_id,
        sales.user_id as user_id,
        min(toStartOfMonth(sales.sale_date)) as first_dlc_month
    from sales
    inner join dlcs on sales.dlc_id = dlcs.dlc_id
    where sales.product_type = 'dlc'
    group by dlcs.game_id, sales.user_id
),

game_bounds as (
    select
        game_id,
        min(first_owned_month) as game_start_month
    from game_first_purchase
    where game_id in (select game_id from games_with_dlcs)
    group by game_id
),

bounds as (
    select max(first_owned_month) as global_max_month
    from game_first_purchase
),

months_spine as (
    select distinct toStartOfMonth(date_day) as month_start
    from {{ ref('DIM_DATE') }}
    where date_day = toStartOfMonth(date_day)
),

grid as (
    select
        game_bounds.game_id as game_id,
        months_spine.month_start as month_start
    from game_bounds
    cross join months_spine
    cross join bounds
    where months_spine.month_start >= game_bounds.game_start_month
      and months_spine.month_start <= bounds.global_max_month
),

new_owners_by_month as (
    select
        game_id,
        first_owned_month as month_start,
        count() as new_owners
    from game_first_purchase
    where game_id in (select game_id from games_with_dlcs)
    group by game_id, first_owned_month
),

new_dlc_owners_by_month as (
    select
        game_id,
        first_dlc_month as month_start,
        count() as new_dlc_owners
    from dlc_first_purchase
    group by game_id, first_dlc_month
),

grid_filled as (
    select
        grid.game_id as game_id,
        grid.month_start as month_start,
        coalesce(new_owners_by_month.new_owners, 0) as new_owners,
        coalesce(new_dlc_owners_by_month.new_dlc_owners, 0) as new_dlc_owners
    from grid
    left join new_owners_by_month
        on grid.game_id = new_owners_by_month.game_id and grid.month_start = new_owners_by_month.month_start
    left join new_dlc_owners_by_month
        on grid.game_id = new_dlc_owners_by_month.game_id and grid.month_start = new_dlc_owners_by_month.month_start
),

windowed as (
    select
        game_id,
        month_start,
        new_owners,
        new_dlc_owners,
        sum(new_owners) over (
            partition by game_id order by month_start rows between unbounded preceding and current row
        ) as cumulative_owners,
        sum(new_dlc_owners) over (
            partition by game_id order by month_start rows between unbounded preceding and current row
        ) as cumulative_dlc_owners
    from grid_filled
),

final as (
    select
        cityHash64(windowed.game_id, windowed.month_start) as row_id,
        windowed.game_id as game_id,
        games.title as game_title,
        games.publisher_name as publisher_name,
        windowed.month_start as month_start,
        toYear(windowed.month_start) as year,
        toMonth(windowed.month_start) as month_num,
        windowed.new_owners as new_owners_this_month,
        windowed.new_dlc_owners as new_dlc_owners_this_month,
        windowed.cumulative_owners as cumulative_owners,
        windowed.cumulative_dlc_owners as cumulative_dlc_owners,
        if(windowed.cumulative_owners = 0, NULL, round(windowed.cumulative_dlc_owners / windowed.cumulative_owners * 100, 2)) as attach_rate_pct
    from windowed
    left join games on windowed.game_id = games.game_id
)

select
    row_id,
    game_id,
    game_title,
    publisher_name,
    month_start,
    year,
    month_num,
    new_owners_this_month,
    new_dlc_owners_this_month,
    cumulative_owners,
    cumulative_dlc_owners,
    attach_rate_pct
from final
