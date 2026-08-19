{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'invoice') }}
),

final as (
    select
        cast(invoice_id as bigint) as invoice_id,
        cast(customer_id as bigint) as customer_id,
        cast(invoice_date as datetime) as invoice_date,
        cast(billing_address as Nullable(String)) as billing_address,
        cast(billing_city as Nullable(String)) as billing_city,
        cast(billing_state as Nullable(String)) as billing_state,
        cast(billing_country as Nullable(String)) as billing_country,
        cast(billing_postal_code as Nullable(String)) as billing_postal_code,
        cast(total as decimal(10, 2)) as total
    from bases
)

select * from final
