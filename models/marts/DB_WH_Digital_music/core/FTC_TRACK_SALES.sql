{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by='toYYYYMM(sale_date)',
    engine='MergeTree()',
    order_by='(sale_date, sale_id)',
    tags=['marts', 'digital_music', 'core']
) }}

-- Grain: une ligne = une piste vendue (invoice_line). Nommé FTC_TRACK_SALES (et pas FTC_SALES,
-- déjà pris par le domaine Digital Gaming) pour éviter toute collision de nom de modèle dbt.
--
-- Incrémental insert_overwrite, partitionné par mois (toYYYYMM(sale_date)) : chaque run recharge
-- les N derniers mois COMPLETS (var dm_incremental_lookback_months) puis remplace les partitions
-- correspondantes de façon atomique (REPLACE PARTITION), sans DELETE ligne à ligne. Même logique
-- que FTC_SALES côté Digital Gaming -- voir son commentaire pour le détail du piège
-- "> dernier timestamp chargé" à éviter.

with invoice_lines as (
    select
        invoice_line_id,
        invoice_id,
        customer_id,
        track_id,
        track_name,
        unit_price,
        quantity,
        line_total,
        invoice_date
    from {{ ref('int_dm_invoice_lines') }}
    {% if is_incremental() %}
    where invoice_date >= dateTrunc('month', now()) - interval {{ var('dm_incremental_lookback_months') }} month
    {% endif %}
),

final as (
    select
        invoice_line_id as sale_id,
        invoice_id,
        customer_id,
        track_id,
        track_name,
        unit_price,
        quantity,
        line_total as sale_amount,
        invoice_date as sale_at,
        toDate(invoice_date) as sale_date
    from invoice_lines
)

select
    sale_id,
    invoice_id,
    customer_id,
    track_id,
    track_name,
    unit_price,
    quantity,
    sale_amount,
    sale_at,
    sale_date
from final
