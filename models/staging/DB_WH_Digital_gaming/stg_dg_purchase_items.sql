{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'purchase_items') }}
),

final as (
    select
        cast(id as bigint) as purchase_item_id,
        cast(purchase_id as bigint) as purchase_id,
        cast(game_id as Nullable(bigint)) as game_id,
        cast(dlc_id as Nullable(bigint)) as dlc_id,
        cast(price as decimal(10, 2)) as price
    from bases
)

select * from final
