{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'developers') }}
),

final as (
    select
        cast(id as bigint) as developer_id,
        cast(name as String) as name,
        cast(website as String) as website,
        cast(founded_date as date) as founded_date
    from bases
)

select * from final
