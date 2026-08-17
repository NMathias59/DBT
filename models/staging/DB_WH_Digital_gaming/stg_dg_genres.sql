{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'genres') }}
),

final as (
    select
        cast(id as bigint) as genre_id,
        cast(name as String) as name,
        cast(description as String) as description
    from bases
)

select * from final
