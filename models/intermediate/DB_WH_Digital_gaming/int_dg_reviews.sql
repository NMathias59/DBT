{{ config(
    materialized='view',
    tags=['intermediate', 'digital_gaming']
) }}

with reviews as (
    select * from {{ ref('stg_dg_reviews') }}
),

review_votes as (
    select * from {{ ref('stg_dg_review_votes') }}
),

dlcs as (
    select * from {{ ref('stg_dg_dlcs') }}
),

votes_agg as (
    select
        review_id,
        count() as total_votes,
        sum(is_helpful) as helpful_votes
    from review_votes
    group by review_id
),

-- Pas de table "mises à jour/patchs" dans le domaine : les DLC sont le seul événement produit
-- disponible pour contextualiser une chute de sentiment (ex: vague d'avis négatifs après une sortie).
reviews_prior_dlcs as (
    select
        reviews.review_id as review_id,
        dlcs.dlc_id as dlc_id,
        dateDiff('day', dlcs.release_date, toDate(reviews.created_at)) as days_since_dlc
    from reviews
    inner join dlcs on reviews.game_id = dlcs.game_id
    where dlcs.release_date <= toDate(reviews.created_at)
),

closest_dlc as (
    -- toNullable(...) explicite : sinon un LEFT JOIN sur ces colonnes non-nullables renvoie la
    -- valeur par défaut du type (0) pour les reviews sans DLC antérieur, au lieu de NULL --
    -- ce qui donnerait un faux "DLC sorti aujourd'hui" (dlc_id=0, days=0) au lieu de "pas de DLC".
    select
        review_id,
        toNullable(argMin(dlc_id, days_since_dlc)) as nearest_dlc_id,
        toNullable(min(days_since_dlc)) as days_since_last_dlc_release
    from reviews_prior_dlcs
    group by review_id
),

final as (
    select
        reviews.review_id as review_id,
        reviews.user_id as user_id,
        reviews.game_id as game_id,
        reviews.is_recommended as is_recommended,
        reviews.created_at as created_at,
        votes_agg.total_votes as total_votes,
        votes_agg.helpful_votes as helpful_votes,
        if(votes_agg.total_votes = 0, NULL, votes_agg.helpful_votes / votes_agg.total_votes) as helpful_ratio,
        closest_dlc.nearest_dlc_id as nearest_prior_dlc_id,
        closest_dlc.days_since_last_dlc_release as days_since_last_dlc_release
    from reviews
    left join votes_agg on reviews.review_id = votes_agg.review_id
    left join closest_dlc on reviews.review_id = closest_dlc.review_id
)

select * from final
