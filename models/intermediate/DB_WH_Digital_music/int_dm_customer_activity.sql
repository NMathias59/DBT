{{ config(
    materialized='view',
    tags=['intermediate', 'digital_music']
) }}

with customers as (
    select * from {{ ref('stg_dm_customer') }}
),

invoices as (
    select * from {{ ref('stg_dm_invoice') }}
),

invoice_lines as (
    select * from {{ ref('stg_dm_invoice_line') }}
),

invoice_agg as (
    select
        customer_id,
        count() as total_invoices,
        sum(total) as total_spent,
        min(invoice_date) as first_purchase_at,
        max(invoice_date) as last_purchase_at
    from invoices
    group by customer_id
),

-- Volume de pistes achetées : passe par invoice_lines (pas invoices.total) car un même customer_id
-- peut apparaître plusieurs fois par facture (une ligne par piste) -- count()/sum(quantity) donnent
-- le nombre réel de pistes, pas de facture.
tracks_agg as (
    select
        invoices.customer_id as customer_id,
        sum(invoice_lines.quantity) as tracks_purchased
    from invoice_lines
    left join invoices on invoice_lines.invoice_id = invoices.invoice_id
    group by invoices.customer_id
),

final as (
    select
        customers.customer_id as customer_id,
        customers.first_name,
        customers.last_name,
        customers.country,
        customers.support_rep_id as support_rep_id,
        invoice_agg.total_invoices as total_invoices,
        invoice_agg.total_spent as total_spent,
        tracks_agg.tracks_purchased as tracks_purchased,
        invoice_agg.first_purchase_at as first_purchase_at,
        invoice_agg.last_purchase_at as last_purchase_at
    from customers
    left join invoice_agg on customers.customer_id = invoice_agg.customer_id
    left join tracks_agg on customers.customer_id = tracks_agg.customer_id
)

select * from final
