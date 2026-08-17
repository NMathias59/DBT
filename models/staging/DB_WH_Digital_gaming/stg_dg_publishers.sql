{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'publishers') }}
),

final as (
    select
        cast(id as bigint) as publisher_id,
        cast(name as String) as name,
        cast(website as String) as website,
        cast(founded_date as date) as founded_date
    from bases
)

select * from final
