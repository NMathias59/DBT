{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(artist_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = un artiste. Dimension type 1 (pas d'historisation), full rebuild à chaque
-- run, volume faible (catalogue Chinook). album_count/track_count agrégés pour éviter de
-- recompter côté BI.

with artists as (
    select * from {{ ref('stg_dm_artist') }}
),

albums as (
    select * from {{ ref('stg_dm_album') }}
),

tracks as (
    select * from {{ ref('stg_dm_track') }}
),

albums_agg as (
    select
        artist_id,
        count() as album_count
    from albums
    group by artist_id
),

-- count() sur un LEFT JOIN non matché renvoie naturellement 0 (0 est la valeur correcte pour
-- "aucun album/aucune piste"), même logique que int_dg_market_listings.txn_agg.
tracks_agg as (
    select
        albums.artist_id as artist_id,
        count() as track_count
    from tracks
    left join albums on tracks.album_id = albums.album_id
    where albums.artist_id is not null
    group by albums.artist_id
),

final as (
    select
        artists.artist_id as artist_id,
        artists.name as artist_name,
        albums_agg.album_count as album_count,
        tracks_agg.track_count as track_count
    from artists
    left join albums_agg on artists.artist_id = albums_agg.artist_id
    left join tracks_agg on artists.artist_id = tracks_agg.artist_id
)

select
    artist_id,
    artist_name,
    album_count,
    track_count
from final
