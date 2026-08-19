{{ config(
    materialized='view',
    tags=['self_service', 'digital_music']
) }}

-- Grain: une ligne = une vente (piste), enrichie pour l'analyse métier sans jointure à faire côté
-- BI : calendrier, client, piste/album/artiste/genre. DIM_DATE réutilisée depuis Digital Gaming
-- (dimension générique, pas spécifique à un domaine -- voir son commentaire dans
-- marts/DB_WH_Digital_gaming/core/DIM_DATE.sql).

with sales as (
    select
        sale_id,
        sale_at,
        sale_date,
        customer_id,
        track_id,
        unit_price,
        quantity,
        sale_amount
    from {{ ref('FTC_TRACK_SALES') }}
),

tracks as (
    select
        track_id,
        track_name,
        album_title,
        artist_name,
        genre_name,
        media_type_name
    from {{ ref('DIM_TRACKS') }}
),

customers as (
    select
        customer_id,
        first_name,
        last_name,
        country
    from {{ ref('DIM_CUSTOMERS') }}
),

dates as (
    select
        date_day,
        year,
        quarter,
        month,
        month_name,
        is_weekend
    from {{ ref('DIM_DATE') }}
),

final as (
    select
        sales.sale_id as sale_id,
        sales.sale_at as sale_at,
        sales.sale_date as sale_date,
        dates.year as sale_year,
        dates.quarter as sale_quarter,
        dates.month as sale_month,
        dates.month_name as sale_month_name,
        dates.is_weekend as sale_is_weekend,
        sales.customer_id as customer_id,
        customers.first_name as customer_first_name,
        customers.last_name as customer_last_name,
        customers.country as customer_country,
        sales.track_id as track_id,
        tracks.track_name as track_name,
        tracks.album_title as album_title,
        tracks.artist_name as artist_name,
        tracks.genre_name as genre_name,
        tracks.media_type_name as media_type_name,
        sales.unit_price as unit_price,
        sales.quantity as quantity,
        sales.sale_amount as sale_amount
    from sales
    left join tracks on sales.track_id = tracks.track_id
    left join customers on sales.customer_id = customers.customer_id
    left join dates on sales.sale_date = dates.date_day
)

select
    sale_id,
    sale_at,
    sale_date,
    sale_year,
    sale_quarter,
    sale_month,
    sale_month_name,
    sale_is_weekend,
    customer_id,
    customer_first_name,
    customer_last_name,
    customer_country,
    track_id,
    track_name,
    album_title,
    artist_name,
    genre_name,
    media_type_name,
    unit_price,
    quantity,
    sale_amount
from final
