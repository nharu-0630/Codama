create table if not exists public.areas (
    id bigint primary key generated always as identity,
    name text not null,
    created_at timestamptz default now()
);
