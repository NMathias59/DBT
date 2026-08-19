{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(album_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = un album, avec l'artiste résolu en clair et des agrégats de pistes.
-- Full rebuild à chaque run, volume faible.

with albums as (
    select * from {{ ref('stg_dm_album') }}
),

artists as (
    select * from {{ ref('stg_dm_artist') }}
),

tracks as (
    select * from {{ ref('stg_dm_track') }}
),

tracks_agg as (
    select
        album_id,
        count() as track_count,
        sum(milliseconds) as total_duration_ms
    from tracks
    where album_id is not null
    group by album_id
),

final as (
    select
        albums.album_id as album_id,
        albums.title as album_title,
        albums.artist_id as artist_id,
        artists.name as artist_name,
        tracks_agg.track_count as track_count,
        tracks_agg.total_duration_ms as total_duration_ms
    from albums
    left join artists on albums.artist_id = artists.artist_id
    left join tracks_agg on albums.album_id = tracks_agg.album_id
)

select
    album_id,
    album_title,
    artist_id,
    artist_name,
    track_count,
    total_duration_ms
from final
