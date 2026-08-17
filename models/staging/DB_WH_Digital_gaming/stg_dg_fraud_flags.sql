{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'fraud_flags') }}
),

final as (
    select
        cast(id as bigint) as fraud_flag_id,
        cast(user_id as bigint) as user_id,
        cast(flagged_at as datetime) as flagged_at,
        cast(flag_type as String) as flag_type,
        cast(status as String) as status,
        cast(related_market_transaction_id as Nullable(bigint)) as related_market_transaction_id
    from bases
)

select * from final
