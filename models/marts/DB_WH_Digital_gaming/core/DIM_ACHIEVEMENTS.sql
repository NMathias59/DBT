{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(achievement_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un succès du catalogue (catalogue statique, jamais exploité seul jusqu'ici).
-- Complète FTC_USER_ACHIEVEMENTS (points, nom, jeu parent).

with achievements as (
    select
        achievement_id,
        game_id,
        name,
        points
    from {{ ref('stg_dg_achievements') }}
),

games as (
    select
        game_id,
        title
    from {{ ref('stg_dg_games') }}
),

final as (
    select
        achievements.achievement_id as achievement_id,
        achievements.game_id as game_id,
        games.title as game_title,
        achievements.name as achievement_name,
        achievements.points as points
    from achievements
    left join games on achievements.game_id = games.game_id
)

select
    achievement_id,
    game_id,
    game_title,
    achievement_name,
    points
from final
