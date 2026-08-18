{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(month_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = un mois. Revenu récurrent (MRR) des abonnements, nombre d'abonnements/
-- abonnés actifs, nouveaux abonnements, résiliations et taux de résiliation mensuel.
--
-- mrr_usd : plan_price normalisé sur 30 jours (plan_price * 30 / billing_period_days) pour rendre
-- comparables des formules mensuelles/trimestrielles/annuelles -- approximation standard MRR, pas
-- un calcul de facturation réelle au jour près.
--
-- "Actif ce mois-là" = start_date au plus tard le dernier jour du mois ET (end_date NULL OU
-- end_date au plus tôt le premier jour du mois) -- un abonnement actif ne serait-ce qu'un jour
-- dans le mois compte pour tout le mois (mesure de présence, pas de prorata au jour).
--
-- churn_rate_pct = résiliations du mois / abonnements actifs au mois précédent. NULL au premier
-- mois disponible (pas de mois précédent pour comparer).

with subs as (
    select
        subscription_id,
        user_id,
        plan_price,
        billing_period_days,
        start_date,
        end_date
    from {{ ref('FTC_SUBSCRIPTIONS') }}
),

bounds as (
    select
        min(start_date) as global_min_date,
        max(coalesce(end_date, today())) as global_max_date
    from subs
),

months_spine as (
    select distinct
        toStartOfMonth(date_day) as month_start,
        toLastDayOfMonth(date_day) as month_end
    from {{ ref('DIM_DATE') }}
    where date_day = toStartOfMonth(date_day)
),

months_in_range as (
    select months_spine.month_start as month_start, months_spine.month_end as month_end
    from months_spine
    cross join bounds
    where months_spine.month_start <= bounds.global_max_date
      and months_spine.month_end >= bounds.global_min_date
),

active_by_month as (
    select
        months_in_range.month_start as month_start,
        subs.subscription_id as subscription_id,
        subs.user_id as user_id,
        subs.plan_price as plan_price,
        subs.billing_period_days as billing_period_days
    from months_in_range
    cross join subs
    where subs.start_date <= months_in_range.month_end
      and (subs.end_date is null or subs.end_date >= months_in_range.month_start)
),

monthly_active_agg as (
    select
        month_start,
        count() as active_subscriptions,
        count(distinct user_id) as active_subscribers,
        round(sum(toFloat64(plan_price) * 30.0 / billing_period_days), 2) as mrr_usd
    from active_by_month
    group by month_start
),

new_subs_by_month as (
    select
        toStartOfMonth(start_date) as month_start,
        count() as new_subscriptions
    from subs
    group by month_start
),

churned_by_month as (
    select
        toStartOfMonth(end_date) as month_start,
        count() as churned_subscriptions
    from subs
    where end_date is not null
    group by month_start
),

combined as (
    select
        months_in_range.month_start as month_start,
        coalesce(monthly_active_agg.active_subscriptions, 0) as active_subscriptions,
        coalesce(monthly_active_agg.active_subscribers, 0) as active_subscribers,
        coalesce(monthly_active_agg.mrr_usd, 0) as mrr_usd,
        coalesce(new_subs_by_month.new_subscriptions, 0) as new_subscriptions,
        coalesce(churned_by_month.churned_subscriptions, 0) as churned_subscriptions
    from months_in_range
    left join monthly_active_agg on months_in_range.month_start = monthly_active_agg.month_start
    left join new_subs_by_month on months_in_range.month_start = new_subs_by_month.month_start
    left join churned_by_month on months_in_range.month_start = churned_by_month.month_start
),

final as (
    select
        cityHash64(month_start) as row_id,
        month_start,
        toYear(month_start) as year,
        toMonth(month_start) as month_num,
        active_subscriptions,
        active_subscribers,
        mrr_usd,
        new_subscriptions,
        churned_subscriptions,
        -- toNullable(...) : lagInFrame renvoie 0 (pas NULL) au premier mois faute de ligne
        -- précédente -- même piège que les autres modèles de tendance.
        lagInFrame(toNullable(active_subscriptions)) over (order by month_start) as active_subscriptions_prior_month,
        if(
            lagInFrame(toNullable(active_subscriptions)) over (order by month_start) is null
            or lagInFrame(toNullable(active_subscriptions)) over (order by month_start) = 0,
            NULL,
            round(churned_subscriptions / lagInFrame(toNullable(active_subscriptions)) over (order by month_start) * 100, 2)
        ) as churn_rate_pct
    from combined
)

select
    row_id,
    month_start,
    year,
    month_num,
    active_subscriptions,
    active_subscribers,
    mrr_usd,
    new_subscriptions,
    churned_subscriptions,
    active_subscriptions_prior_month,
    churn_rate_pct
from final
