{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'groups') }}
),

final as (
    select
        cast(id as bigint) as group_id,
        cast(owner_id as bigint) as owner_id,
        cast(name as String) as name,
        cast(description as String) as description,
        cast(created_at as datetime) as created_at
    from bases
)

select * from final
