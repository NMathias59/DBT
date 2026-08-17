{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by='toYYYYMM(sale_date)',
    engine='MergeTree()',
    order_by='(sale_date, sale_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un article acheté (purchase_item) = une vente primaire (revenu plateforme/éditeur).
-- Le marché secondaire (échanges C2C d'objets) est un processus distinct -> voir FTC_MARKET_TRANSACTIONS.
--
-- Incrémental insert_overwrite, partitionné par mois (toYYYYMM(sale_date)) : chaque run recharge les
-- N derniers mois COMPLETS (var dg_incremental_lookback_months) puis remplace les partitions
-- correspondantes de façon atomique (REPLACE PARTITION), sans DELETE ligne à ligne.
--
-- ATTENTION : le filtre doit toujours couvrir des partitions entières, jamais un simple
-- "> dernier timestamp chargé" comme en delete_insert -- sinon REPLACE PARTITION écraserait aussi
-- les lignes déjà chargées du mois qui ne seraient pas resélectionnées par le filtre.

with purchases as (
    select * from {{ ref('int_dg_purchases') }}
    {% if is_incremental() %}
    where purchased_at >= dateTrunc('month', now()) - interval {{ var('dg_incremental_lookback_months') }} month
    {% endif %}
),

final as (
    select
        purchase_item_id as sale_id,
        purchase_id,
        user_id,
        payment_method_id,
        payment_provider,
        product_type,
        game_id,
        dlc_id,
        product_title,
        item_price as sale_amount,
        purchased_at as sale_at,
        toDate(purchased_at) as sale_date
    from purchases
)

select * from final
