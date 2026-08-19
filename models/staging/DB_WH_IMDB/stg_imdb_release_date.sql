{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

-- Table source vide (0 ligne) sur ce jeu de données -- voir stg_imdb_certificate. release_date
-- gardé en String (format non observable, table vide) plutôt que casté en date.

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'release_dates') }}
),

final as (
    select
        cast(movie_id as bigint) as movie_id,
        cast(country as String) as country,
        cast(release_date as String) as release_date,
        cast(note as Nullable(String)) as note
    from bases
)

select * from final
