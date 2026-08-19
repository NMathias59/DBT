{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(genre, month_start)',
    tags=['self_service', 'digital_music']
) }}

-- Grain: une ligne = (genre, month_start). revenue_share_pct = part de marché du genre ce
-- mois-là. Contrairement à genre_popularity_trends côté Digital Gaming, une piste a exactement
-- UN genre (pas de multi-valorisation) -- pas de double comptage, la somme des
-- revenue_share_pct de tous les genres sur un même mois fait ~100%.
--
-- Pas de grille zero-fill par genre (comme genre_popularity_trends) : un genre sans vente un
-- mois donné n'apparaît simplement pas ce mois-là.

with sales as (
    select
        track_id,
        sale_amount,
        sale_date
    from {{ ref('FTC_TRACK_SALES') }}
),

tracks as (
    select
        track_id,
        genre_name
    from {{ ref('DIM_TRACKS') }}
),

-- coalesce(..., 'Unknown') : quelques pistes du catalogue Chinook n'ont pas de genre renseigné
-- (genre_id NULL) -- regroupées explicitement plutôt que silencieusement exclues de l'analyse.
sales_genre as (
    select
        toStartOfMonth(sales.sale_date) as month_start,
        coalesce(tracks.genre_name, 'Unknown') as genre,
        sales.sale_amount as sale_amount
    from sales
    left join tracks on sales.track_id = tracks.track_id
),

monthly_genre_agg as (
    select
        genre,
        month_start,
        sum(sale_amount) as revenue_usd,
        count() as units_sold
    from sales_genre
    group by genre, month_start
),

monthly_total as (
    select
        month_start,
        sum(sale_amount) as total_revenue_usd
    from sales_genre
    group by month_start
),

combined as (
    select
        monthly_genre_agg.genre as genre,
        monthly_genre_agg.month_start as month_start,
        monthly_genre_agg.revenue_usd as revenue_usd,
        monthly_genre_agg.units_sold as units_sold,
        monthly_total.total_revenue_usd as total_revenue_usd,
        round(monthly_genre_agg.revenue_usd / monthly_total.total_revenue_usd * 100, 2) as revenue_share_pct
    from monthly_genre_agg
    left join monthly_total on monthly_genre_agg.month_start = monthly_total.month_start
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
        total_revenue_usd,
        revenue_share_pct,
        -- toNullable(...) : lagInFrame renvoie 0 (pas NULL) au premier mois disponible pour un
        -- genre, faute de ligne précédente -- même piège que subscription_revenue_trends.
        lagInFrame(toNullable(revenue_share_pct)) over (
            partition by genre order by month_start
        ) as revenue_share_pct_prior_month,
        revenue_share_pct - lagInFrame(toNullable(revenue_share_pct)) over (
            partition by genre order by month_start
        ) as revenue_share_pct_change_mom
    from combined
)

select
    row_id,
    genre,
    month_start,
    year,
    month_num,
    revenue_usd,
    units_sold,
    total_revenue_usd,
    revenue_share_pct,
    revenue_share_pct_prior_month,
    revenue_share_pct_change_mom
from final
