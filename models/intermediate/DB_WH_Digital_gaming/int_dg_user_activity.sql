{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with users as (
    select * from {{ ref('stg_dg_users') }}
),

login_events as (
    select * from {{ ref('stg_dg_login_events') }}
),

libraries as (
    select * from {{ ref('stg_dg_libraries') }}
),

user_achievements as (
    select * from {{ ref('stg_dg_user_achievements') }}
),

login_agg as (
    select
        user_id,
        count() as total_logins,
        sum(is_suspicious) as suspicious_logins,
        max(event_time) as last_login_at
    from login_events
    group by user_id
),

library_agg as (
    select
        user_id,
        count() as games_owned,
        sum(playtime_minutes) as total_playtime_minutes
    from libraries
    group by user_id
),

achievements_agg as (
    select
        user_id,
        count() as achievements_unlocked
    from user_achievements
    group by user_id
),

final as (
    select
        users.user_id as user_id,
        users.username as username,
        login_agg.total_logins as total_logins,
        login_agg.suspicious_logins as suspicious_logins,
        login_agg.last_login_at as last_login_at,
        library_agg.games_owned as games_owned,
        library_agg.total_playtime_minutes as total_playtime_minutes,
        achievements_agg.achievements_unlocked as achievements_unlocked
    from users
    left join login_agg on users.user_id = login_agg.user_id
    left join library_agg on users.user_id = library_agg.user_id
    left join achievements_agg on users.user_id = achievements_agg.user_id
)

select * from final
