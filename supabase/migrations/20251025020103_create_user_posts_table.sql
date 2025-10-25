create table if not exists public.user_posts (
    id bigint primary key generated always as identity,
    uuid uuid unique not null,
    content text not null,
    user_uuid uuid not null references auth.users on delete cascade,
    cell_id bigint references public.cells(id),
    created_at timestamptz default now()
);
