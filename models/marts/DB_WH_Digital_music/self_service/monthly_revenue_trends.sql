{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(month_start)',
    tags=['self_service', 'digital_music']
) }}

-- Grain: une ligne = un mois. Revenu global, pistes vendues, clients distincts, cumul à date et
-- 12 mois glissants -- pensé pour la tendance long terme, même logique que
-- game_sales_monthly_revenue / subscription_revenue_trends côté Digital Gaming.
--
-- Grille mensuelle complète (mois sans vente = 0), pas seulement les mois avec ventes -- sinon
-- "12 mois glissants" ne représenterait pas 12 mois calendaires.

with sales as (
    select
        customer_id,
        sale_amount,
        sale_date
    from {{ ref('FTC_TRACK_SALES') }}
),

bounds as (
    select
        min(sale_date) as global_min_date,
        max(sale_date) as global_max_date
    from sales
),

months_spine as (
    select distinct
        toStartOfMonth(date_day) as month_start
    from {{ ref('DIM_DATE') }}
    where date_day = toStartOfMonth(date_day)
),

months_in_range as (
    select months_spine.month_start as month_start
    from months_spine
    cross join bounds
    where months_spine.month_start <= bounds.global_max_date
      and months_spine.month_start >= toStartOfMonth(bounds.global_min_date)
),

monthly_agg as (
    select
        toStartOfMonth(sale_date) as month_start,
        sum(sale_amount) as revenue_usd,
        count() as tracks_sold,
        count(distinct customer_id) as distinct_customers
    from sales
    group by month_start
),

combined as (
    select
        months_in_range.month_start as month_start,
        coalesce(monthly_agg.revenue_usd, 0) as revenue_usd,
        coalesce(monthly_agg.tracks_sold, 0) as tracks_sold,
        coalesce(monthly_agg.distinct_customers, 0) as distinct_customers
    from months_in_range
    left join monthly_agg on months_in_range.month_start = monthly_agg.month_start
),

final as (
    select
        cityHash64(month_start) as row_id,
        month_start,
        toYear(month_start) as year,
        toMonth(month_start) as month_num,
        revenue_usd,
        tracks_sold,
        distinct_customers,
        sum(revenue_usd) over (
            order by month_start
            rows between unbounded preceding and current row
        ) as cumulative_revenue_usd,
        sum(revenue_usd) over (
            order by month_start
            rows between 11 preceding and current row
        ) as rolling_12m_revenue_usd
    from combined
)

select
    row_id,
    month_start,
    year,
    month_num,
    revenue_usd,
    tracks_sold,
    distinct_customers,
    cumulative_revenue_usd,
    rolling_12m_revenue_usd
from final
