{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'purchases') }}
),

final as (
    select
        cast(id as bigint) as purchase_id,
        cast(user_id as bigint) as user_id,
        cast(payment_method_id as bigint) as payment_method_id,
        cast(total_amount as decimal(10, 2)) as total_amount,
        cast(purchased_at as datetime) as purchased_at
    from bases
)

select * from final
