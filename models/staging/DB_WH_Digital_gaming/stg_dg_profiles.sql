{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'profiles') }}
),

final as (
    select
        cast(id as bigint) as profile_id,
        cast(user_id as bigint) as user_id,
        cast(display_name as String) as display_name,
        cast(avatar_url as String) as avatar_url,
        cast(bio as String) as bio,
        cast(level as int) as level
    from bases
)

select * from final
