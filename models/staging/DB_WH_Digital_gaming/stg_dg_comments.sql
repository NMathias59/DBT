{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'comments') }}
),

final as (
    select  
        cast(id as bigint) as comment_id,
        cast(user_id as bigint) as user_id,
        cast(screenshot_id as Nullable(bigint)) as screenshot_id,
        cast(profile_id as Nullable(bigint)) as profile_id,
        cast(content as String) as content,
        cast(created_at as datetime) as created_at
    from bases
)
select * from final
