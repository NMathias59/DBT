{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(month_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = un mois. Signalements de fraude et connexions suspectes dans le temps.
--
-- Pas de ventilation par flag_type ici : seulement 25 signalements sur ~4 ans de données (2 types
-- seulement), une ventilation mensuelle par type serait presque entièrement à zéro et peu
-- lisible. Pour une analyse par flag_type, filtrer directement FTC_FRAUD_FLAGS.
--
-- resolution_rate_pct : dans les données actuelles, TOUS les signalements sont status='open'
-- (aucun résolu) -- ce taux est donc à 0% partout pour l'instant, colonne prête pour quand des
-- signalements commenceront à être traités.
--
-- Grille mensuelle complète sur la plage combinée fraud_flags + login_events : les fraudes sont
-- rares, la plupart des mois affichent 0 signalement -- un vrai zéro, pas un trou de données.

with fraud_flags as (
    select
        flagged_at,
        status
    from {{ ref('FTC_FRAUD_FLAGS') }}
),

login_events as (
    select
        event_time,
        is_suspicious
    from {{ ref('FTC_LOGIN_EVENTS') }}
),

monthly_fraud_agg as (
    select
        toStartOfMonth(flagged_at) as month_start,
        count() as total_fraud_flags,
        countIf(status != 'open') as resolved_fraud_flags
    from fraud_flags
    group by month_start
),

monthly_login_agg as (
    select
        toStartOfMonth(event_time) as month_start,
        count() as total_logins,
        countIf(is_suspicious) as suspicious_logins
    from login_events
    group by month_start
),

bounds as (
    select
        least(min(fraud_flags.flagged_at), min(login_events.event_time)) as global_min_date,
        greatest(max(fraud_flags.flagged_at), max(login_events.event_time)) as global_max_date
    from fraud_flags, login_events
),

months_spine as (
    select distinct toStartOfMonth(date_day) as month_start
    from {{ ref('DIM_DATE') }}
    where date_day = toStartOfMonth(date_day)
),

months_in_range as (
    select months_spine.month_start as month_start
    from months_spine
    cross join bounds
    where months_spine.month_start >= toStartOfMonth(bounds.global_min_date)
      and months_spine.month_start <= toStartOfMonth(bounds.global_max_date)
),

combined as (
    select
        months_in_range.month_start as month_start,
        coalesce(monthly_fraud_agg.total_fraud_flags, 0) as total_fraud_flags,
        coalesce(monthly_fraud_agg.resolved_fraud_flags, 0) as resolved_fraud_flags,
        coalesce(monthly_login_agg.total_logins, 0) as total_logins,
        coalesce(monthly_login_agg.suspicious_logins, 0) as suspicious_logins
    from months_in_range
    left join monthly_fraud_agg on months_in_range.month_start = monthly_fraud_agg.month_start
    left join monthly_login_agg on months_in_range.month_start = monthly_login_agg.month_start
),

final as (
    select
        cityHash64(month_start) as row_id,
        month_start,
        toYear(month_start) as year,
        toMonth(month_start) as month_num,
        total_fraud_flags,
        resolved_fraud_flags,
        if(total_fraud_flags = 0, NULL, round(resolved_fraud_flags / total_fraud_flags * 100, 2)) as resolution_rate_pct,
        total_logins,
        suspicious_logins,
        if(total_logins = 0, NULL, round(suspicious_logins / total_logins * 100, 2)) as suspicious_login_rate_pct
    from combined
)

select
    row_id,
    month_start,
    year,
    month_num,
    total_fraud_flags,
    resolved_fraud_flags,
    resolution_rate_pct,
    total_logins,
    suspicious_logins,
    suspicious_login_rate_pct
from final
