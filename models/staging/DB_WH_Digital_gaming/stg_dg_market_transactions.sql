{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'market_transactions') }}
),

final as (
    select
        cast(id as bigint) as market_transaction_id,
        cast(listing_id as bigint) as listing_id,
        cast(buyer_id as bigint) as buyer_id,
        cast(sold_at as datetime) as sold_at,
        cast(final_price as decimal(10, 2)) as final_price
    from bases
)

select * from final
