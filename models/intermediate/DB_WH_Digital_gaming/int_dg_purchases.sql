{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with purchase_items as (
    select * from {{ ref('stg_dg_purchase_items') }}
),

purchases as (
    select * from {{ ref('stg_dg_purchases') }}
),

payment_methods as (
    select * from {{ ref('stg_dg_payment_methods') }}
),

games as (
    select * from {{ ref('stg_dg_games') }}
),

dlcs as (
    select * from {{ ref('stg_dg_dlcs') }}
),

-- toNullable(...) explicite : sur une ligne d'achat de DLC (game_id NULL), le LEFT JOIN sur games
-- renvoie '' (défaut du type String) et non NULL -- coalesce(games.title, dlcs.title) gardait donc
-- ce '' au lieu de basculer sur dlcs.title. Même piège que int_dg_reviews/int_dg_fraud_flags.
games_titled as (
    select game_id, toNullable(title) as title from games
),

dlcs_titled as (
    select dlc_id, toNullable(title) as title from dlcs
),

final as (
    select
        purchase_items.purchase_item_id as purchase_item_id,
        purchase_items.purchase_id as purchase_id,
        purchases.user_id as user_id,
        purchases.purchased_at as purchased_at,
        purchases.total_amount as purchase_total_amount,
        purchases.payment_method_id as payment_method_id,
        payment_methods.provider as payment_provider,
        purchase_items.game_id as game_id,
        purchase_items.dlc_id as dlc_id,
        multiIf(
            purchase_items.game_id is not null, 'game',
            purchase_items.dlc_id is not null, 'dlc',
            'unknown'
        ) as product_type,
        coalesce(games_titled.title, dlcs_titled.title) as product_title,
        purchase_items.price as item_price
    from purchase_items
    left join purchases on purchase_items.purchase_id = purchases.purchase_id
    left join payment_methods on purchases.payment_method_id = payment_methods.payment_method_id
    left join games_titled on purchase_items.game_id = games_titled.game_id
    left join dlcs_titled on purchase_items.dlc_id = dlcs_titled.dlc_id
)

select * from final
