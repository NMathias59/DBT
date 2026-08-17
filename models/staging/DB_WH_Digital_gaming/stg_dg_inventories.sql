{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'inventories') }}
),

final as (
    select
        cast(id as bigint) as inventory_id,
        cast(user_id as bigint) as user_id,
        cast(item_id as bigint) as item_id,
        cast(acquired_at as datetime) as acquired_at
    from bases
)

select * from final
