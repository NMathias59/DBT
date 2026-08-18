{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(cohort_month, months_since_cohort)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (mois de cohorte, mois depuis la cohorte). Cohorte = mois de première
-- connexion d'un utilisateur (FTC_LOGIN_EVENTS). Rétention = part des utilisateurs de la cohorte
-- encore actifs (au moins une connexion) N mois plus tard.
--
-- months_since_cohort plafonné à 0-12 : au-delà, trop peu de cohortes ont assez de recul dans les
-- données actuelles pour être significatif -- à étendre si l'historique s'allonge.
--
-- Grille complète (cohort_month x months_since_cohort 0-12), limitée aux combinaisons dont le mois
-- cible ne dépasse pas le dernier mois de connexion connu (pas de ligne "future" qui afficherait un
-- faux 0% de rétention pour un mois qui n'est simplement pas encore arrivé). retained_users = 0 est
-- un vrai zéro (personne revenu) seulement pour les combinaisons dans la plage observable.

with login_events as (
    select
        user_id,
        event_time
    from {{ ref('FTC_LOGIN_EVENTS') }}
),

user_cohort as (
    select
        user_id,
        min(toStartOfMonth(event_time)) as cohort_month
    from login_events
    group by user_id
),

user_monthly_active as (
    select distinct
        user_id,
        toStartOfMonth(event_time) as active_month
    from login_events
),

activity_with_cohort as (
    select
        user_monthly_active.user_id as user_id,
        user_cohort.cohort_month as cohort_month,
        dateDiff('month', user_cohort.cohort_month, user_monthly_active.active_month) as months_since_cohort
    from user_monthly_active
    left join user_cohort on user_monthly_active.user_id = user_cohort.user_id
),

cohort_sizes as (
    select
        cohort_month,
        count(distinct user_id) as cohort_size
    from user_cohort
    group by cohort_month
),

bounds as (
    select max(active_month) as global_max_active_month
    from user_monthly_active
),

months_since_range as (
    -- toInt64(...) : numbers() renvoie UInt64, dateDiff('month', ...) renvoie Int64 -- sans ce
    -- cast, ClickHouse refuse la jointure faute de type commun signé/non-signé.
    select toInt64(number) as months_since_cohort
    from numbers(13)
),

grid as (
    select
        cohort_sizes.cohort_month as cohort_month,
        months_since_range.months_since_cohort as months_since_cohort
    from cohort_sizes
    cross join months_since_range
    cross join bounds
    where addMonths(cohort_sizes.cohort_month, months_since_range.months_since_cohort) <= bounds.global_max_active_month
),

retention_agg as (
    select
        cohort_month,
        months_since_cohort,
        count(distinct user_id) as retained_users
    from activity_with_cohort
    where months_since_cohort between 0 and 12
    group by cohort_month, months_since_cohort
),

final as (
    select
        cityHash64(grid.cohort_month, grid.months_since_cohort) as row_id,
        grid.cohort_month as cohort_month,
        grid.months_since_cohort as months_since_cohort,
        cohort_sizes.cohort_size as cohort_size,
        coalesce(retention_agg.retained_users, 0) as retained_users,
        round(coalesce(retention_agg.retained_users, 0) / cohort_sizes.cohort_size * 100, 2) as retention_rate_pct
    from grid
    left join cohort_sizes on grid.cohort_month = cohort_sizes.cohort_month
    left join retention_agg
        on grid.cohort_month = retention_agg.cohort_month
        and grid.months_since_cohort = retention_agg.months_since_cohort
)

select
    row_id,
    cohort_month,
    months_since_cohort,
    cohort_size,
    retained_users,
    retention_rate_pct
from final
