{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(date_day)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Dimension calendaire générique (pas spécifique à Digital Gaming, réutilisable par tout domaine).
-- Grain: une ligne par jour, 2020-01-01 -> 2030-12-31 (large marge autour des données actuelles,
-- 2022-07 -> 2026-08 dans FTC_SALES). Table statique, pas besoin de rebuild fréquent.

with date_spine as (
    select toDate('2020-01-01') + number as date_day
    from numbers(toUInt32(dateDiff('day', toDate('2020-01-01'), toDate('2030-12-31'))) + 1)
),

final as (
    select
        date_day,
        toYYYYMMDD(date_day) as date_id,
        toYear(date_day) as year,
        toQuarter(date_day) as quarter,
        toMonth(date_day) as month,
        dateName('month', date_day) as month_name,
        toDayOfMonth(date_day) as day_of_month,
        toDayOfWeek(date_day) as day_of_week,
        dateName('weekday', date_day) as day_name,
        toISOWeek(date_day) as iso_week,
        if(toDayOfWeek(date_day) in (6, 7), true, false) as is_weekend,
        toYYYYMM(date_day) as year_month
    from date_spine
)

select
    date_day,
    date_id,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_of_week,
    day_name,
    iso_week,
    is_weekend,
    year_month
from final
