{{ config(
    materialized='view',
    tags=['intermediate', 'digital_music']
) }}

with tracks as (
    select * from {{ ref('stg_dm_track') }}
),

albums as (
    select * from {{ ref('stg_dm_album') }}
),

artists as (
    select * from {{ ref('stg_dm_artist') }}
),

genres as (
    select * from {{ ref('stg_dm_genre') }}
),

media_types as (
    select * from {{ ref('stg_dm_media_type') }}
),

-- toNullable(...) explicite : track.album_id est nullable (piste hors album), donc le LEFT JOIN
-- sur albums peut ne pas matcher -- sans ce cast, albums.title (String non-nullable) renverrait ''
-- (défaut du type) au lieu de NULL pour ces pistes. Même piège que int_dg_purchases/int_dg_reviews.
albums_titled as (
    select album_id, artist_id, toNullable(title) as title from albums
),

final as (
    select
        tracks.track_id as track_id,
        tracks.name as track_name,
        tracks.composer,
        tracks.milliseconds,
        tracks.bytes,
        tracks.unit_price,
        tracks.album_id as album_id,
        albums_titled.title as album_title,
        albums_titled.artist_id as artist_id,
        artists.name as artist_name,
        tracks.genre_id as genre_id,
        genres.name as genre_name,
        tracks.media_type_id as media_type_id,
        media_types.name as media_type_name
    from tracks
    left join albums_titled on tracks.album_id = albums_titled.album_id
    left join artists on albums_titled.artist_id = artists.artist_id
    left join genres on tracks.genre_id = genres.genre_id
    left join media_types on tracks.media_type_id = media_types.media_type_id
)

select * from final
