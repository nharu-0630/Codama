create index if not exists idx_user_posts_cell_id on public.user_posts (cell_id);

create index if not exists idx_user_posts_uuid on public.user_posts (uuid);

create index if not exists idx_user_posts_created_at on public.user_posts (created_at desc);

create index if not exists idx_user_posts_cell_created_at on public.user_posts (cell_id, created_at desc);

create index if not exists idx_llm_posts_user_post_uuid on public.llm_posts (user_post_uuid);

create index if not exists idx_cells_geo_hash on public.cells (geo_hash);

create index if not exists idx_cells_area_id on public.cells (area_id);

create index if not exists idx_cells_location_gist on public.cells using gist (location);

create index if not exists idx_prompts_area_id on public.prompts (area_id);

create index if not exists idx_embedding_user_posts_uuid on public.embedding_user_posts (user_post_uuid);

create index if not exists idx_friends_user_uuid on public.friends (user_uuid);
create index if not exists idx_friends_friend_uuid on public.friends (friend_uuid);
create index if not exists idx_friends_cell_id on public.friends (cell_id);

create index if not exists idx_user_post_pairs_cell_id on public.user_post_pairs (cell_id);
create index if not exists idx_user_post_pairs_created_at on public.user_post_pairs (created_at desc);
