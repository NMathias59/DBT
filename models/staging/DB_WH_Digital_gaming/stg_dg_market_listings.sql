{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'market_listings') }}
),

final as (
    select
        cast(id as bigint) as listing_id,
        cast(seller_id as bigint) as seller_id,
        cast(item_id as bigint) as item_id,
        cast(price as decimal(10, 2)) as price,
        cast(listed_at as datetime) as listed_at,
        cast(is_sold as bool) as is_sold
    from bases
)

select * from final
