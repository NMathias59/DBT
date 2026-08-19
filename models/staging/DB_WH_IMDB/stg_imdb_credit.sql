{{ config(
    materialized='view',
    tags=['staging', 'imdb']
) }}

with bases as (
    select *
    from {{ source('DB_WH_IMDB', 'credits') }}
),

final as (
    select
        cast(person_id as bigint) as person_id,
        cast(movie_id as bigint) as movie_id,
        cast(type as String) as type,
        cast(note as Nullable(String)) as note,
        cast(character as Nullable(String)) as character,
        -- position/line_order/group_order/subgroup_order : 100% NULL sur ce jeu de données
        -- (ordre de crédit non renseigné en source) -- conservées telles quelles.
        cast(position as Nullable(bigint)) as position,
        cast(line_order as Nullable(bigint)) as line_order,
        cast(group_order as Nullable(bigint)) as group_order,
        cast(subgroup_order as Nullable(bigint)) as subgroup_order
    from bases
)

select * from final
