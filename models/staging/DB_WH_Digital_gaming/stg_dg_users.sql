{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'users') }}
),

final as (
    select
        cast(id as bigint) as user_id,
        cast(username as String) as username,
        cast(email as String) as email,
        cast(password_hash as String) as password_hash,
        cast(created_at as datetime) as created_at
    from bases
)

select * from final
