alter table if exists public.llm_posts
add column if not exists location geography(POINT);
