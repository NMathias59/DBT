{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'people') }}
),

final as (
    select
        cast(id as bigint) as person_id,
        cast(name as String) as name,
        -- gender : 100% NULL sur ce jeu de données (colonne jamais renseignée en source) --
        -- conservée telle quelle, pas de valeur à en déduire côté staging.
        cast(gender as Nullable(String)) as gender
    from bases
)

select * from final
