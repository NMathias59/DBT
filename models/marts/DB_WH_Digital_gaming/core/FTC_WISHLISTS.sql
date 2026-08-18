{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(added_at, wishlist_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un ajout d'un jeu à la liste de souhaits. Signal de demande, utile pour un
-- funnel wishlist -> achat (rapprocher de FTC_SALES sur user_id + game_id).
--
-- Pas de clé source (table de jonction pure user_id/game_id/added_at) : wishlist_id est une clé
-- de substitution (hash des 3 colonnes). Un même couple (user_id, game_id) peut apparaître
-- plusieurs fois (ré-ajout après retrait) -- 1256 lignes pour 938 couples distincts constaté sur
-- les données réelles, comportement volontairement conservé (pas de déduplication).
--
-- Table full rebuild : contenu immuable une fois ajouté, mais volume faible donc pas besoin
-- d'incrémental.

with wishlists as (
    select
        user_id,
        game_id,
        added_at
    from {{ ref('stg_dg_wishlists') }}
),

final as (
    select
        cityHash64(user_id, game_id, added_at) as wishlist_id,
        user_id,
        game_id,
        added_at
    from wishlists
)

select
    wishlist_id,
    user_id,
    game_id,
    added_at
from final
