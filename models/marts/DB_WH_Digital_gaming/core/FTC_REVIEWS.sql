{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(created_at, review_id)',
    tags=['marts', 'digital_gaming', 'core']
) }}

-- Grain: une ligne = un avis posté sur un jeu.
--
-- Table full rebuild (PAS d'incrémental) : contrairement à FTC_SALES, les mesures agrégées
-- (total_votes / helpful_votes / helpful_ratio) continuent de changer après la création de l'avis,
-- à chaque nouveau vote reçu. Un filtre incrémental sur created_at capterait les nouveaux avis mais
-- laisserait les compteurs des anciens avis obsolètes. Volume faible (~2k avis), rebuild complet
-- largement suffisant.
--
-- nearest_prior_dlc_id / days_since_last_dlc_release : contexte pour repérer une chute de sentiment
-- liée à la sortie d'un DLC (pas de table "mises à jour" dans le domaine, DLC = seul proxy dispo).

with reviews as (
    select * from {{ ref('int_dg_reviews') }}
),

final as (
    select
        review_id,
        user_id,
        game_id,
        is_recommended,
        total_votes,
        helpful_votes,
        helpful_ratio,
        created_at,
        nearest_prior_dlc_id,
        days_since_last_dlc_release
    from reviews
)

select * from final
