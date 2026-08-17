{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'tags') }}
),

final as (
    select
        cast(id as bigint) as tag_id,
        cast(name as String) as name
    from bases
)

select * from final
