{{ config(
    materialized='view',
    tags=['staging', 'digital_music']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_music', 'invoice_line') }}
),

final as (
    select
        cast(invoice_line_id as bigint) as invoice_line_id,
        cast(invoice_id as bigint) as invoice_id,
        cast(track_id as bigint) as track_id,
        cast(unit_price as decimal(10, 2)) as unit_price,
        cast(quantity as bigint) as quantity
    from bases
)

select * from final
