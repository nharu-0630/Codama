create extension if not exists vector with schema extensions;

create table if not exists public.embedding_user_posts (
    id bigint primary key generated always as identity,
    embedding vector(1536) not null,
    user_post_uuid uuid not null references public.user_posts(uuid) on delete cascade,
    created_at timestamptz default now()
);