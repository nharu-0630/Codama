create schema if not exists "postgis";
grant usage on schema "postgis" to "postgres";

create extension if not exists postgis with schema postgis;

create table if not exists public.cells (
    id bigint primary key generated always as identity,
    geo_hash text unique not null,
    location postgis.geography(POINT) not null,
    area_id bigint references public.areas(id),
    created_at timestamptz default now()
);
