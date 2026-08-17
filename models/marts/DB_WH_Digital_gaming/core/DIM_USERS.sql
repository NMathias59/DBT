{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(user_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un utilisateur, avec ses agrégats d'activité (logins, bibliothèque, succès).
-- Full rebuild à chaque run, volume faible, permet de croiser FTC_SALES / FTC_MARKET_TRANSACTIONS /
-- FTC_REVIEWS / FTC_SUBSCRIPTIONS par utilisateur.

with user_activity as (
    select * from {{ ref('int_dg_user_activity') }}
),

final as (
    select
        user_id,
        username,
        total_logins,
        suspicious_logins,
        last_login_at,
        games_owned,
        total_playtime_minutes,
        achievements_unlocked
    from user_activity
)

select * from final
