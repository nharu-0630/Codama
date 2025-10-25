alter table if exists public.user_posts
add column if not exists location geography(POINT);
