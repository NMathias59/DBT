{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

-- Table source vide (0 ligne) sur ce jeu de données -- vue créée pour la complétude du domaine
-- (staging = 1:1 sur toute table déclarée en source) et pour ne rien casser le jour où elle
-- serait alimentée. Non consommée par intermediate/marts tant qu'elle reste vide -- voir
-- imdb_overview.

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'certificates') }}
),

final as (
    select
        cast(movie_id as bigint) as movie_id,
        cast(country as String) as country,
        cast(certificate as String) as certificate,
        cast(note as Nullable(String)) as note
    from bases
)

select * from final
