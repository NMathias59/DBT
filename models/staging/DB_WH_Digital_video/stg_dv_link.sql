{{ config(
    materialized='view',
    tags=['staging', 'digital_video']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_video', 'links') }}
),

final as (
    select
        cast(movieId as bigint) as movie_id,
        -- imdb_id : identifiant IMDb sans le préfixe "tt" (toujours 7 chiffres sur ce jeu de
        -- données), conservé en String (zéros non significatifs) plutôt que casté en nombre.
        cast(imdbId as String) as imdb_id,
        cast(tmdbId as Nullable(bigint)) as tmdb_id
    from bases
)

select * from final
