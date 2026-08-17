{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(dlc_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un DLC. Complète DIM_GAMES pour les ventes de FTC_SALES où
-- product_type = 'dlc' (jusqu'ici seul product_title était dénormalisé dans le fact, pas de
-- possibilité d'analyser par jeu parent / prix catalogue / date de sortie du DLC).

with dlcs as (
    select * from {{ ref('stg_dg_dlcs') }}
),

games as (
    select * from {{ ref('stg_dg_games') }}
),

final as (
    select
        dlcs.dlc_id as dlc_id,
        dlcs.game_id as game_id,
        games.title as game_title,
        dlcs.title as dlc_title,
        dlcs.price as price,
        dlcs.release_date as release_date
    from dlcs
    left join games on dlcs.game_id = games.game_id
)

select * from final
