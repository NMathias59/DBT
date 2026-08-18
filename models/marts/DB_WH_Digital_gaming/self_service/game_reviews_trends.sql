{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(game_id, week_start)',
    tags=['self_service', 'digital_gaming']
) }}

-- Grain: une ligne = (jeu, semaine). Pensé pour l'avis général par jeu, agrégeable au grain
-- semaine/mois/année selon le besoin -- semaine = grain le plus fin demandé, month_start et year
-- sont fournis pour regrouper directement sans recalcul de date côté BI.
--
-- ATTENTION agrégation : review_count / recommended_count / total_votes / helpful_votes sont des
-- mesures additives (on peut les resommer sans souci en regroupant par month_start ou year).
-- recommendation_rate et helpfulness_rate sont calculés à CE grain (semaine) -- si tu regroupes
-- par mois/année, il faut recalculer le taux à partir des sommes (sum(recommended_count) /
-- sum(review_count)), jamais moyenner les taux hebdomadaires entre eux (une semaine à 2 avis ne
-- doit pas peser autant qu'une semaine à 50 avis dans une moyenne).
--
-- week_start = début de semaine au dimanche (comportement par défaut de toStartOfWeek en
-- ClickHouse).

with reviews as (
    select
        game_id,
        is_recommended,
        total_votes,
        helpful_votes,
        created_at
    from {{ ref('FTC_REVIEWS') }}
),

games as (
    select
        game_id,
        title,
        publisher_name,
        developer_name
    from {{ ref('DIM_GAMES') }}
),

weekly_agg as (
    select
        game_id,
        toStartOfWeek(created_at) as week_start,
        count() as review_count,
        countIf(is_recommended) as recommended_count,
        sum(total_votes) as total_votes_sum,
        sum(helpful_votes) as helpful_votes_sum
    from reviews
    group by game_id, week_start
),

final as (
    select
        cityHash64(weekly_agg.game_id, weekly_agg.week_start) as row_id,
        weekly_agg.game_id as game_id,
        games.title as game_title,
        games.publisher_name as publisher_name,
        games.developer_name as developer_name,
        weekly_agg.week_start as week_start,
        toStartOfMonth(weekly_agg.week_start) as month_start,
        toYear(weekly_agg.week_start) as year,
        weekly_agg.review_count as review_count,
        weekly_agg.recommended_count as recommended_count,
        weekly_agg.recommended_count / weekly_agg.review_count as recommendation_rate,
        weekly_agg.total_votes_sum as total_votes,
        weekly_agg.helpful_votes_sum as helpful_votes,
        if(weekly_agg.total_votes_sum = 0, NULL, weekly_agg.helpful_votes_sum / weekly_agg.total_votes_sum) as helpfulness_rate
    from weekly_agg
    left join games on weekly_agg.game_id = games.game_id
)

select
    row_id,
    game_id,
    game_title,
    publisher_name,
    developer_name,
    week_start,
    month_start,
    year,
    review_count,
    recommended_count,
    recommendation_rate,
    total_votes,
    helpful_votes,
    helpfulness_rate
from final
