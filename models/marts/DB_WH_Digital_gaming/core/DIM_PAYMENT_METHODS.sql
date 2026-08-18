{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(payment_method_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un moyen de paiement. Complète FTC_SALES (payment_method_id/payment_provider
-- déjà dénormalisés dans le fact) pour des analyses par provider, expiration, ou multi-moyens de
-- paiement par utilisateur.
--
-- account_number volontairement exclu : donnée sensible (PII) sans valeur analytique, ne doit pas
-- être exposée dans un mart business-facing même si présente en staging.

with payment_methods as (
    select
        payment_method_id,
        user_id,
        provider,
        expiry_date
    from {{ ref('stg_dg_payment_methods') }}
),

final as (
    select
        payment_method_id,
        user_id,
        provider,
        expiry_date
    from payment_methods
)

select
    payment_method_id,
    user_id,
    provider,
    expiry_date
from final
