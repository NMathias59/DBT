{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(employee_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = un employé, avec son manager résolu en clair et le nombre de clients
-- rattachés (int_dm_employees). Full rebuild à chaque run, volume faible (8 employés).

with employees as (
    select
        employee_id,
        first_name,
        last_name,
        title,
        hire_date,
        reports_to,
        manager_first_name,
        manager_last_name,
        customers_supported
    from {{ ref('int_dm_employees') }}
),

final as (
    select
        employee_id,
        first_name,
        last_name,
        title,
        hire_date,
        reports_to,
        manager_first_name,
        manager_last_name,
        customers_supported
    from employees
)

select
    employee_id,
    first_name,
    last_name,
    title,
    hire_date,
    reports_to,
    manager_first_name,
    manager_last_name,
    customers_supported
from final
