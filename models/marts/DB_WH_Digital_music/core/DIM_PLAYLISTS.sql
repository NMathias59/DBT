{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(playlist_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = une playlist, avec nb de pistes/durée totale agrégés (int_dm_playlists).
-- Full rebuild à chaque run, volume faible.

with playlists as (
    select
        playlist_id,
        playlist_name,
        track_count,
        total_duration_ms,
        track_ids
    from {{ ref('int_dm_playlists') }}
),

final as (
    select
        playlist_id,
        playlist_name,
        track_count,
        total_duration_ms,
        track_ids
    from playlists
)

select
    playlist_id,
    playlist_name,
    track_count,
    total_duration_ms,
    track_ids
from final
