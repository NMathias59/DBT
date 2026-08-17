{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'games') }}
),

final as (
    select
        cast(id as bigint) as game_id,
        cast(title as String) as title,
        cast(description as String) as description,
        cast(price as decimal(10, 2)) as price,
        cast(release_date as date) as release_date,
        cast(publisher_id as bigint) as publisher_id,
        cast(developer_id as bigint) as developer_id
    from bases
)

select * from final
