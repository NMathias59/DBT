{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'customer') }}
),

final as (
    select
        cast(customer_id as bigint) as customer_id,
        cast(first_name as String) as first_name,
        cast(last_name as String) as last_name,
        cast(company as Nullable(String)) as company,
        cast(address as Nullable(String)) as address,
        cast(city as Nullable(String)) as city,
        cast(state as Nullable(String)) as state,
        cast(country as Nullable(String)) as country,
        cast(postal_code as Nullable(String)) as postal_code,
        cast(phone as Nullable(String)) as phone,
        cast(fax as Nullable(String)) as fax,
        cast(email as String) as email,
        cast(support_rep_id as Nullable(bigint)) as support_rep_id
    from bases
)

select * from final
