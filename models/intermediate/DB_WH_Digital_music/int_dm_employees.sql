{{ config(
    materialized='view',
    tags=['intermediate', 'digital_music']
) }}

with employees as (
    select * from {{ ref('stg_dm_employee') }}
),

customers as (
    select * from {{ ref('stg_dm_customer') }}
),

-- toNullable(...) explicite : employee.reports_to est nullable (ex: le manager général n'a pas de
-- supérieur), donc le LEFT JOIN sur managers peut ne pas matcher -- sans ce cast, first_name/
-- last_name (String non-nullable) renverraient '' au lieu de NULL. Même piège que int_dm_tracks.
managers as (
    select
        employee_id,
        toNullable(first_name) as first_name,
        toNullable(last_name) as last_name
    from employees
),

customers_agg as (
    select
        support_rep_id as employee_id,
        count() as customers_supported
    from customers
    where support_rep_id is not null
    group by support_rep_id
),

final as (
    select
        employees.employee_id as employee_id,
        employees.first_name as first_name,
        employees.last_name as last_name,
        employees.title,
        employees.hire_date,
        employees.reports_to as reports_to,
        managers.first_name as manager_first_name,
        managers.last_name as manager_last_name,
        -- count() sur un LEFT JOIN non matché renvoie naturellement 0 (pas de piège Nullable ici,
        -- 0 est la valeur correcte pour "aucun client rattaché"). Même logique que
        -- int_dg_market_listings.txn_agg.
        customers_agg.customers_supported as customers_supported
    from employees
    left join managers on employees.reports_to = managers.employee_id
    left join customers_agg on employees.employee_id = customers_agg.employee_id
)

select * from final
