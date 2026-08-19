{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'employee') }}
),

final as (
    select
        cast(employee_id as bigint) as employee_id,
        cast(last_name as String) as last_name,
        cast(first_name as String) as first_name,
        cast(title as Nullable(String)) as title,
        cast(reports_to as Nullable(bigint)) as reports_to,
        cast(birth_date as Nullable(datetime)) as birth_date,
        cast(hire_date as Nullable(datetime)) as hire_date,
        cast(address as Nullable(String)) as address,
        cast(city as Nullable(String)) as city,
        cast(state as Nullable(String)) as state,
        cast(country as Nullable(String)) as country,
        cast(postal_code as Nullable(String)) as postal_code,
        cast(phone as Nullable(String)) as phone,
        cast(fax as Nullable(String)) as fax,
        cast(email as Nullable(String)) as email
    from bases
)

select * from final
