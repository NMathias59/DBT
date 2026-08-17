{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'dlcs') }}
),

final as (
    select
        cast(id as bigint) as dlc_id,
        cast(game_id as bigint) as game_id,
        cast(title as String) as title,
        cast(price as decimal(10, 2)) as price,
        cast(release_date as date) as release_date
    from bases
)

select * from final
