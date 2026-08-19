{{ config(
    materialized='view',
    tags=['staging', 'digital_video']
) }}

with bases as (
    select *
    from {{ source('DB_WH_Digital_video', 'tags') }}
),

final as (
    select
        cast(userId as bigint) as user_id,
        cast(movieId as bigint) as movie_id,
        cast(tag as String) as tag,
        -- timestamp source = epoch Unix (secondes), même conversion que stg_dv_rating.
        fromUnixTimestamp(toUInt32(timestamp)) as tagged_at
    from bases
)

select * from final
