{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'screenshots') }}
),

final as (
    select
        cast(id as bigint) as screenshot_id,
        cast(user_id as bigint) as user_id,
        cast(game_id as bigint) as game_id,
        cast(image_url as String) as image_url,
        cast(caption as String) as caption,
        cast(uploaded_at as datetime) as uploaded_at
    from bases
)

select * from final
