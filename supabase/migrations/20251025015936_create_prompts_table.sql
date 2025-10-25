create table if not exists public.prompts (
    id bigint primary key generated always as identity,
    prompt text not null,
    area_id bigint references public.areas(id),
    created_at timestamptz default now()
);
