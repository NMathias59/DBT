{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

-- Table source vide (0 ligne) sur ce jeu de données -- voir stg_imdb_certificate.

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'color_info') }}
),

final as (
    select
        cast(movie_id as bigint) as movie_id,
        cast(value as String) as value,
        cast(note as Nullable(String)) as note
    from bases
)

select * from final
