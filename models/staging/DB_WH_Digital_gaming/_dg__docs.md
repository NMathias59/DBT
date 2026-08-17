{% docs dg_overview %}

## Digital Gaming

Domaine couvrant la plateforme de jeux vidéo dématérialisés du groupe : catalogue de jeux, comptes
utilisateurs, achats/paiements, marché secondaire d'objets in-game, vie sociale (amis, groupes, chats),
avis, succès et sécurité/fraude.

Schéma source ClickHouse : `DB_WH_DIGITAL_GAMING` — 37 tables, staging avec le préfixe `stg_dg_*`.

### Périmètre fonctionnel

**Catalogue & contenu**
`games`, `dlcs`, `genres`, `game_genres`, `tags`, `game_tags`, `developers`, `publishers`,
`system_requirements`, `news_articles`, `achievements`, `items`

**Comptes & profils**
`users`, `profiles`, `login_events`

**Social**
`friends`, `friend_requests`, `groups`, `group_members`, `chats`, `chat_members`, `chat_messages`,
`comments`, `screenshots`

**Bibliothèque & progression**
`libraries`, `wishlists`, `user_achievements`, `inventories`

**Achats & paiement**
`purchases`, `purchase_items`, `payment_methods`, `subscriptions`, `subscription_plans`

**Marché secondaire (trading d'objets in-game)**
`market_listings`, `market_transactions`

**Avis & modération**
`reviews`, `review_votes`, `fraud_flags`

### Conventions de staging

- Toutes les vues `stg_dg_*` sont matérialisées en `view` et taguées `staging`, `digital_gaming`.
- L'identifiant technique `id` de chaque table est renommé en `<entité>_id` explicite
  (ex : `games.id` → `game_id`, `users.id` → `user_id`) pour éviter toute ambiguïté dans les jointures.
- Les colonnes nullables côté source sont castées en `Nullable(...)` pour préserver le comportement
  d'origine (ex : `comments.screenshot_id`, `subscriptions.end_date`).
- Les tables de jointure pure (ex : `game_genres`, `game_tags`, `user_achievements`, `wishlists`,
  `friends`, `friend_requests`, `group_members`) n'ont pas de clé primaire propre : elles exposent
  directement leurs clés étrangères.

### Relations clés

- `games` ← `developers` / `publishers` (via `developer_id` / `publisher_id`)
- `purchases` → `purchase_items` → `games` / `dlcs`
- `market_listings` → `market_transactions` (via `listing_id`)
- `users` ↔ `profiles`, `users` → `libraries` → `games`
- `users` → `subscriptions` → `subscription_plans`

{% enddocs %}
