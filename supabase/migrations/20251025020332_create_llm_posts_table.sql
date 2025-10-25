create table if not exists llm_posts (
    id bigint primary key generated always as identity,
    uuid uuid unique not null,
    content text not null,
    user_post_uuid uuid not null references public.user_posts(uuid) on delete cascade,
    created_at timestamptz default now()
);
