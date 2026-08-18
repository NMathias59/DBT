{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(game_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un jeu du catalogue. Dimension type 1 (pas d'historisation) : full rebuild
-- à chaque run, volume faible (catalogue de jeux) donc pas besoin d'incrémental ici.

with games as (
    select
        game_id,
        title,
        price,
        release_date,
        publisher_id,
        publisher_name,
        developer_id,
        developer_name,
        genre_ids,
        genre_names,
        tag_ids,
        tag_names,
        operating_system,
        processor,
        memory,
        graphics,
        storage
    from {{ ref('int_dg_games') }}
),

final as (
    select
        game_id,
        title,
        price,
        release_date,
        publisher_id,
        publisher_name,
        developer_id,
        developer_name,
        genre_ids,
        genre_names,
        tag_ids,
        tag_names,
        operating_system,
        processor,
        memory,
        graphics,
        storage
    from games
)

select
    game_id,
    title,
    price,
    release_date,
    publisher_id,
    publisher_name,
    developer_id,
    developer_name,
    genre_ids,
    genre_names,
    tag_ids,
    tag_names,
    operating_system,
    processor,
    memory,
    graphics,
    storage
from final
