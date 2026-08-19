{{ config(
    materialized='table',
    engine='MergeTree()',
    order_by='(movie_id, person_id)',
    tags=['marts', 'imdb', 'core']
) }}

-- Grain: une ligne = un crédit (personne x film x rôle). credit_id = clé de substitution (hash
-- de person_id/movie_id/type/character, pas de clé source) -- ce quadruplet est unique sur ce
-- jeu de données.
--
-- Table full rebuild (PAS d'incrémental, contrairement à FTC_SALES/FTC_TRACK_SALES/FTC_RATINGS) :
-- ce domaine n'a aucune dimension temporelle événementielle (pas de "date du crédit") -- movies.
-- year est un attribut du film, pas un axe d'arrivée des lignes. Rien à partitionner par mois/
-- année ici, contrairement aux autres domaines -- voir imdb_overview.

with credits as (
    select
        person_id,
        person_name,
        movie_id,
        movie_title,
        movie_year,
        credit_type,
        character,
        note
    from {{ ref('int_imdb_credits') }}
),

final as (
    select
        cityHash64(person_id, movie_id, credit_type, coalesce(character, '')) as credit_id,
        person_id,
        person_name,
        movie_id,
        movie_title,
        movie_year,
        credit_type,
        character,
        note
    from credits
)

select
    credit_id,
    person_id,
    person_name,
    movie_id,
    movie_title,
    movie_year,
    credit_type,
    character,
    note
from final
