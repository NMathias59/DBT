{{ config(
    materialized='view',
    tags=['staging', 'digital_video']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_video', 'movies') }}
),

final as (
    select
        cast(movieId as bigint) as movie_id,
        cast(title as String) as title,
        -- genres brut, pipe-délimité (ex: "Adventure|Animation|Comedy"), sentinelle
        -- "(no genres listed)" si aucun genre -- éclatement en tableau fait en intermediate
        -- (int_dv_movies), pas ici (staging = 1:1, pas de logique métier).
        cast(genres as String) as genres
    from bases
)

select * from final
