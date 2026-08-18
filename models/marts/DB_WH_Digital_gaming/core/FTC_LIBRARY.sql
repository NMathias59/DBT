{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(purchase_date, library_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un jeu en bibliothèque d'un utilisateur. Distinct de FTC_SALES : un jeu en
-- bibliothèque n'est pas forcément passé par un achat (offert, gratuit, promo...), donc pas de
-- purchase_id ici -- juste le fait de possession + usage.
--
-- Table full rebuild (pas d'incrémental) : playtime_minutes augmente en continu après
-- purchase_date à mesure que l'utilisateur joue, même piège que FTC_REVIEWS/FTC_SUBSCRIPTIONS.

with libraries as (
    select
        library_id,
        user_id,
        game_id,
        purchase_date,
        playtime_minutes
    from {{ ref('stg_dg_libraries') }}
),

final as (
    select
        library_id,
        user_id,
        game_id,
        purchase_date,
        playtime_minutes
    from libraries
)

select
    library_id,
    user_id,
    game_id,
    purchase_date,
    playtime_minutes
from final
