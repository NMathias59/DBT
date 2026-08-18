{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(entity_type, entity_name, month_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (entity_type ['item_type'|'item_rarity'], entity_name, mois). Tendance du
-- marché secondaire (FTC_MARKET_TRANSACTIONS) par type et par rareté d'objet -- même structure
-- que genre_popularity_trends/publisher_developer_trends. item_type et item_rarity sont
-- mono-valués par objet (contrairement au genre d'un jeu), donc pas de double comptage : la
-- somme des revenue_share_pct de tous les item_type (ou de toutes les item_rarity) sur un même
-- mois fait exactement 100%.
--
-- avg_price_variance : moyenne de (final_price - listed_price) -- positif = les objets de ce
-- type/rareté se vendent en moyenne AU-DESSUS du prix affiché (forte demande), négatif = en
-- dessous.

with market_transactions as (
    select
        sale_date,
        final_price,
        price_variance,
        item_type,
        item_rarity
    from {{ ref('FTC_MARKET_TRANSACTIONS') }}
),

monthly_market_total as (
    select
        toStartOfMonth(sale_date) as month_start,
        sum(final_price) as total_value_usd
    from market_transactions
    group by month_start
),

type_agg as (
    select
        'item_type' as entity_type,
        item_type as entity_name,
        toStartOfMonth(sale_date) as month_start,
        sum(final_price) as value_usd,
        count() as transaction_count,
        avg(price_variance) as avg_price_variance
    from market_transactions
    group by entity_type, entity_name, month_start
),

rarity_agg as (
    select
        'item_rarity' as entity_type,
        item_rarity as entity_name,
        toStartOfMonth(sale_date) as month_start,
        sum(final_price) as value_usd,
        count() as transaction_count,
        avg(price_variance) as avg_price_variance
    from market_transactions
    group by entity_type, entity_name, month_start
),

combined as (
    select * from type_agg
    union all
    select * from rarity_agg
),

with_share as (
    select
        combined.entity_type as entity_type,
        combined.entity_name as entity_name,
        combined.month_start as month_start,
        combined.value_usd as value_usd,
        combined.transaction_count as transaction_count,
        round(combined.avg_price_variance, 2) as avg_price_variance,
        monthly_market_total.total_value_usd as total_value_usd,
        -- toFloat64(...) : même piège que genre_popularity_trends (division Decimal/Decimal
        -- tronquée à 2 décimales avant le *100).
        round(toFloat64(combined.value_usd) / toFloat64(monthly_market_total.total_value_usd) * 100, 2) as value_share_pct
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
        value_usd,
        transaction_count,
        avg_price_variance,
        total_value_usd,
        value_share_pct,
        -- toNullable(...) : même piège lagInFrame que genre_popularity_trends/publisher_developer_trends.
        lagInFrame(toNullable(value_share_pct)) over (
            partition by entity_type, entity_name order by month_start
        ) as value_share_pct_prior_month,
        value_share_pct - lagInFrame(toNullable(value_share_pct)) over (
            partition by entity_type, entity_name order by month_start
        ) as value_share_pct_change_mom
    from with_share
)

select
    row_id,
    entity_type,
    entity_name,
    month_start,
    year,
    month_num,
    value_usd,
    transaction_count,
    avg_price_variance,
    total_value_usd,
    value_share_pct,
    value_share_pct_prior_month,
    value_share_pct_change_mom
from final
