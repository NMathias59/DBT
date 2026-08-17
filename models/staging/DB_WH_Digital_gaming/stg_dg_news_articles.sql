{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'news_articles') }}
),

final as (
    select
        cast(id as bigint) as article_id,
        cast(game_id as bigint) as game_id,
        cast(title as String) as title,
        cast(content as String) as content,
        cast(published_at as datetime) as published_at
    from bases
)

select * from final
