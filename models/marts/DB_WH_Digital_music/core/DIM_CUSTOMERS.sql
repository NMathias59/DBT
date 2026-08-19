{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(customer_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = un client, avec ses agrégats d'achat (int_dm_customer_activity). Full
-- rebuild à chaque run, volume faible -- permet de croiser FTC_TRACK_SALES par client sans
-- recalcul côté BI.

with customer_activity as (
    select
        customer_id,
        first_name,
        last_name,
        country,
        support_rep_id,
        total_invoices,
        total_spent,
        tracks_purchased,
        first_purchase_at,
        last_purchase_at
    from {{ ref('int_dm_customer_activity') }}
),

final as (
    select
        customer_id,
        first_name,
        last_name,
        country,
        support_rep_id,
        total_invoices,
        total_spent,
        tracks_purchased,
        first_purchase_at,
        last_purchase_at
    from customer_activity
)

select
    customer_id,
    first_name,
    last_name,
    country,
    support_rep_id,
    total_invoices,
    total_spent,
    tracks_purchased,
    first_purchase_at,
    last_purchase_at
from final
