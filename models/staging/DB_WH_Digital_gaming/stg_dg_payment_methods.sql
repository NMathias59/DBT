{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'payment_methods') }}
),

final as (
    select
        cast(id as bigint) as payment_method_id,
        cast(user_id as bigint) as user_id,
        cast(provider as String) as provider,
        cast(account_number as String) as account_number,
        cast(expiry_date as date) as expiry_date
    from bases
)

select * from final
