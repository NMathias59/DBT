{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(track_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = une piste du catalogue. Dimension type 1, full rebuild à chaque run.
-- Album/artiste/genre/type de média déjà résolus en clair par int_dm_tracks.

with tracks as (
    select
        track_id,
        track_name,
        composer,
        milliseconds,
        bytes,
        unit_price,
        album_id,
        album_title,
        artist_id,
        artist_name,
        genre_id,
        genre_name,
        media_type_id,
        media_type_name
    from {{ ref('int_dm_tracks') }}
),

final as (
    select
        track_id,
        track_name,
        composer,
        milliseconds,
        bytes,
        unit_price,
        album_id,
        album_title,
        artist_id,
        artist_name,
        genre_id,
        genre_name,
        media_type_id,
        media_type_name
    from tracks
)

select
    track_id,
    track_name,
    composer,
    milliseconds,
    bytes,
    unit_price,
    album_id,
    album_title,
    artist_id,
    artist_name,
    genre_id,
    genre_name,
    media_type_id,
    media_type_name
from final
