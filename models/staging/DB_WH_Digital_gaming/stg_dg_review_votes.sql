{{ config(
    materialized='view',
    tags=['staging', 'digital_gaming']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_gaming', 'review_votes') }}
),

final as (
    select
        cast(id as bigint) as review_vote_id,
        cast(review_id as bigint) as review_id,
        cast(user_id as bigint) as user_id,
        cast(is_helpful as bool) as is_helpful
    from bases
)

select * from final
