{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(genre, year)',
    tags=['self_service', 'imdb']
) }}

-- Grain: une ligne = (genre, year). Volume de films et note moyenne par genre dans le temps.
-- Grain annuel (pas mensuel comme les autres domaines) : ce référentiel n'a qu'une date de
-- sortie au niveau année (movies.year), pas de date événementielle fine -- voir imdb_overview.
--
-- ATTENTION genre multi-valué : un film multi-genre compte dans chacun de ses genres -- même
-- logique que genre_ratings_trends côté Digital Video. movie_share_pct (volume) peut donc
-- dépasser 100% en sommant tous les genres d'une même année, normal, pas un bug.

with movies as (
    select
        movie_id,
        year,
        rating,
        genres_list
    from {{ ref('DIM_FILMS') }}
    where year is not null
),

-- arrayJoin explose une ligne par genre du film. if(empty(...)) : un film sans genre (tableau
-- vide) donnerait 0 ligne avec arrayJoin sur [] -- normalisé en 'Unknown' pour ne pas le perdre.
movies_genre as (
    select
        year,
        if(empty(genres_list), 'Unknown', arrayJoin(genres_list)) as genre,
        rating
    from movies
),

yearly_genre_agg as (
    select
        genre,
        year,
        count() as movie_count,
        round(avg(rating), 2) as avg_rating
    from movies_genre
    group by genre, year
),

yearly_total as (
    select
        year,
        count() as total_movie_count
    from movies_genre
    group by year
),

combined as (
    select
        yearly_genre_agg.genre as genre,
        yearly_genre_agg.year as year,
        yearly_genre_agg.movie_count as movie_count,
        yearly_genre_agg.avg_rating as avg_rating,
        yearly_total.total_movie_count as total_movie_count,
        round(yearly_genre_agg.movie_count / yearly_total.total_movie_count * 100, 2) as movie_share_pct
    from yearly_genre_agg
    left join yearly_total on yearly_genre_agg.year = yearly_total.year
),

final as (
    select
        cityHash64(genre, year) as row_id,
        genre,
        -- assumeNotNull(...) : year est filtré non-NULL en amont (where year is not null) mais
        -- reste typé Nullable(Int64) côté ClickHouse -- un simple cast (toInt32/toInt64)
        -- préserve l'enveloppe Nullable, seul assumeNotNull() la retire. Une clé ORDER BY de
        -- MergeTree ne peut pas être Nullable (sauf allow_nullable_key, non activé sur ce
        -- projet).
        assumeNotNull(year) as year,
        movie_count,
        avg_rating,
        total_movie_count,
        movie_share_pct
    from combined
)

select
    row_id,
    genre,
    year,
    movie_count,
    avg_rating,
    total_movie_count,
    movie_share_pct
from final
