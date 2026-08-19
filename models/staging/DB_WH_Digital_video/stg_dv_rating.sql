{{ config(
    materialized='view',
    tags=['staging', 'digital_video']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_video', 'ratings') }}
),

final as (
    select
        cast(userId as bigint) as user_id,
        cast(movieId as bigint) as movie_id,
        cast(rating as Float64) as rating,
        -- timestamp source = epoch Unix (secondes) -- converti en datetime ici (nettoyage de
        -- type, pas de logique métier) pour éviter de propager un entier opaque dans tout le
        -- reste du projet.
        fromUnixTimestamp(toUInt32(timestamp)) as rated_at
    from bases
)

select * from final
