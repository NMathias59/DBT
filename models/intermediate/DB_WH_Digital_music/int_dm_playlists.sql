{{ config(
    materialized='view',
    tags=['intermediate', 'digital_music']
) }}

with playlists as (
    select * from {{ ref('stg_dm_playlist') }}
),

playlist_tracks as (
    select * from {{ ref('stg_dm_playlist_track') }}
),

tracks as (
    select * from {{ ref('stg_dm_track') }}
),

tracks_agg as (
    select
        playlist_tracks.playlist_id as playlist_id,
        count() as track_count,
        sum(tracks.milliseconds) as total_duration_ms,
        groupArray(tracks.track_id) as track_ids
    from playlist_tracks
    left join tracks on playlist_tracks.track_id = tracks.track_id
    group by playlist_tracks.playlist_id
),

final as (
    select
        playlists.playlist_id as playlist_id,
        playlists.name as playlist_name,
        tracks_agg.track_count as track_count,
        tracks_agg.total_duration_ms as total_duration_ms,
        tracks_agg.track_ids as track_ids
    from playlists
    left join tracks_agg on playlists.playlist_id = tracks_agg.playlist_id
)

select * from final
