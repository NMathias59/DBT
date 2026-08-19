{{ config(
    materialized='view',
    tags=['intermediate', 'digital_music']
) }}

with invoice_lines as (
    select * from {{ ref('stg_dm_invoice_line') }}
),

invoices as (
    select * from {{ ref('stg_dm_invoice') }}
),

customers as (
    select * from {{ ref('stg_dm_customer') }}
),

tracks as (
    select * from {{ ref('int_dm_tracks') }}
),

final as (
    select
        invoice_lines.invoice_line_id as invoice_line_id,
        invoice_lines.invoice_id as invoice_id,
        invoices.invoice_date as invoice_date,
        invoices.customer_id as customer_id,
        customers.first_name as customer_first_name,
        customers.last_name as customer_last_name,
        invoices.billing_country as billing_country,
        invoice_lines.track_id as track_id,
        tracks.track_name,
        tracks.album_title,
        tracks.artist_name,
        tracks.genre_name,
        invoice_lines.unit_price as unit_price,
        invoice_lines.quantity as quantity,
        invoice_lines.unit_price * invoice_lines.quantity as line_total
    from invoice_lines
    left join invoices on invoice_lines.invoice_id = invoices.invoice_id
    left join customers on invoices.customer_id = customers.customer_id
    left join tracks on invoice_lines.track_id = tracks.track_id
)

select * from final
