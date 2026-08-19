{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(playlist_id, track_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = une piste dans une playlist (table de faits factless, comme FTC_WISHLISTS
-- côté Digital Gaming). Signal d'engagement, utile pour croiser popularité en playlist et ventes
-- (FTC_TRACK_SALES) par piste/genre/artiste.
--
-- Pas de clé source (table de jonction pure playlist_id/track_id) : playlist_track_id est une clé
-- de substitution (hash des 2 colonnes). Full rebuild : contenu immuable une fois ajouté, volume
-- faible.

with playlist_tracks as (
    select
        playlist_id,
        track_id
    from {{ ref('stg_dm_playlist_track') }}
),

final as (
    select
        cityHash64(playlist_id, track_id) as playlist_track_id,
        playlist_id,
        track_id
    from playlist_tracks
)

select
    playlist_track_id,
    playlist_id,
    track_id
from final
