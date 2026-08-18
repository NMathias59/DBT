{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(unlocked_at, user_achievement_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un déblocage de succès. Jusqu'ici seul un compteur agrégé
-- (achievements_unlocked) existait dans DIM_USERS -- ce fait expose le détail, joignable à
-- DIM_ACHIEVEMENTS (points, jeu) et DIM_USERS.
--
-- Pas de clé source (table de jonction pure user_id/achievement_id/unlocked_at) :
-- user_achievement_id est une clé de substitution. Un même couple (user_id, achievement_id) peut
-- apparaître plusieurs fois dans ce jeu de données (2820 lignes pour 1303 couples distincts) --
-- comportement volontairement conservé, même logique que FTC_WISHLISTS.
--
-- Table full rebuild, volume faible, contenu immuable une fois débloqué.

with user_achievements as (
    select
        user_id,
        achievement_id,
        unlocked_at
    from {{ ref('stg_dg_user_achievements') }}
),

final as (
    select
        cityHash64(user_id, achievement_id, unlocked_at) as user_achievement_id,
        user_id,
        achievement_id,
        unlocked_at
    from user_achievements
)

select
    user_achievement_id,
    user_id,
    achievement_id,
    unlocked_at
from final
