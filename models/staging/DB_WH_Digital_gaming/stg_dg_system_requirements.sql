{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'system_requirements') }}
),

final as (
    select
        cast(id as bigint) as requirement_id,
        cast(game_id as bigint) as game_id,
        cast(operating_system as String) as operating_system,
        cast(processor as String) as processor,
        cast(memory as String) as memory,
        cast(graphics as String) as graphics,
        cast(storage as String) as storage
    from bases
)

select * from final
