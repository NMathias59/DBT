{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(employee_id)',
    tags=['self_service', 'digital_music']
) }}

-- Grain: une ligne = un employé (support commercial). Revenu généré par les clients dont il a la
-- charge (customer.support_rep_id), pas de tendance mensuelle ici -- photo d'ensemble, même
-- logique de grain que wishlist_conversion_funnel côté Digital Gaming.

with employees as (
    select
        employee_id,
        first_name,
        last_name,
        title,
        customers_supported
    from {{ ref('DIM_EMPLOYEES') }}
),

customers as (
    select
        support_rep_id,
        total_spent,
        total_invoices
    from {{ ref('DIM_CUSTOMERS') }}
    where support_rep_id is not null
),

customer_agg as (
    select
        support_rep_id as employee_id,
        sum(total_spent) as revenue_generated,
        sum(total_invoices) as invoices_generated
    from customers
    group by support_rep_id
),

final as (
    select
        employees.employee_id as employee_id,
        employees.first_name as first_name,
        employees.last_name as last_name,
        employees.title as title,
        employees.customers_supported as customers_supported,
        coalesce(customer_agg.revenue_generated, 0) as revenue_generated,
        coalesce(customer_agg.invoices_generated, 0) as invoices_generated,
        -- if(customers_supported = 0, NULL, ...) : évite une division par zéro pour les employés
        -- (managers) sans client rattaché.
        if(
            employees.customers_supported = 0,
            NULL,
            round(coalesce(customer_agg.revenue_generated, 0) / employees.customers_supported, 2)
        ) as avg_revenue_per_customer
    from employees
    left join customer_agg on employees.employee_id = customer_agg.employee_id
)

select
    employee_id,
    first_name,
    last_name,
    title,
    customers_supported,
    revenue_generated,
    invoices_generated,
    avg_revenue_per_customer
from final
