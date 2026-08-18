{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by='toYYYYMM(event_date)',
    engine='MergeTree()',
    order_by='(event_time, login_event_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un événement de connexion. Jusqu'ici seuls des agrégats (total_logins,
-- suspicious_logins, last_login_at) existaient dans DIM_USERS -- ce fait expose le détail
-- (device, ip_address), utile pour corréler avec FTC_FRAUD_FLAGS.
--
-- Contrairement à FTC_REVIEWS/FTC_SUBSCRIPTIONS : un événement de connexion est immuable une fois
-- créé (pas de statut qui évolue après coup) ET le volume grossit en continu (11.8k lignes déjà,
-- table qui grandit indéfiniment) -> insert_overwrite comme FTC_SALES, pas de full rebuild.

with login_events as (
    select
        login_event_id,
        user_id,
        event_time,
        ip_address,
        device,
        event_type,
        is_suspicious
    from {{ ref('stg_dg_login_events') }}
    {% if is_incremental() %}
    where event_time >= dateTrunc('month', now()) - interval {{ var('dg_incremental_lookback_months') }} month
    {% endif %}
),

final as (
    select
        login_event_id,
        user_id,
        event_time,
        toDate(event_time) as event_date,
        ip_address,
        device,
        event_type,
        is_suspicious
    from login_events
)

select
    login_event_id,
    user_id,
    event_time,
    event_date,
    ip_address,
    device,
    event_type,
    is_suspicious
from final
