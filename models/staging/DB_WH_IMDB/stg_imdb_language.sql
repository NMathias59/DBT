{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'languages') }}
),

final as (
    select
        cast(movie_id as bigint) as movie_id,
        cast(language as String) as language,
        -- note : malgré son nom, contient systématiquement (quand renseignée) le titre du film
        -- dans cette langue, pas une note libre -- particularité du jeu de données, conservée
        -- telle quelle (nom de colonne source non modifié).
        cast(note as Nullable(String)) as note
    from bases
)

select * from final
