{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by='toYear(rated_date)',
    engine='MergeTree()',
    order_by='(rated_date, rating_id)',
    tags=['marts', 'digital_video', 'core']
) }}

-- Grain: une ligne = une note posée par un utilisateur sur un film. rating_id = clé de
-- substitution (hash de user_id/movie_id, pas de clé source) -- le couple (user_id, movie_id)
-- est unique sur ce jeu de données (un utilisateur ne note un film qu'une fois).
--
-- Incrémental insert_overwrite, partitionné par ANNÉE (pas par mois comme FTC_SALES côté Digital
-- Gaming) : les notes MovieLens s'étalent sur 1996-2018 (22+ ans), un partitionnement mensuel sur
-- le chargement initial complet produirait 260+ partitions en un seul INSERT -- ClickHouse
-- plafonne à 100 partitions par bloc (max_partitions_per_insert_block) et rejette l'insert. La
-- var dv_incremental_lookback_months reste en mois (chaque run recharge les N derniers mois
-- COMPLETS), REPLACE PARTITION ne remplace alors que la/les partition(s) annuelle(s) concernées
-- -- même piège "> dernier timestamp chargé" à éviter que FTC_SALES, voir son commentaire.

with ratings as (
    select
        user_id,
        movie_id,
        rating,
        rated_at
    from {{ ref('stg_dv_rating') }}
    {% if is_incremental() %}
    where rated_at >= dateTrunc('month', now()) - interval {{ var('dv_incremental_lookback_months') }} month
    {% endif %}
),

final as (
    select
        cityHash64(user_id, movie_id) as rating_id,
        user_id,
        movie_id,
        rating,
        rated_at,
        toDate(rated_at) as rated_date
    from ratings
)

select
    rating_id,
    user_id,
    movie_id,
    rating,
    rated_at,
    rated_date
from final
