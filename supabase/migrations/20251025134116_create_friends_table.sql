create table if not exists public.friends (
    id bigint primary key generated always as identity,
    user_uuid uuid not null references auth.users on delete cascade,
    friend_uuid uuid not null references auth.users on delete cascade,
    cell_id bigint references public.cells(id),
    created_at timestamptz default now(),
    unique (user_uuid, friend_uuid)
);

create or replace function public.create_reciprocal_friend()
returns trigger as $$
begin
    insert into public.friends (user_uuid, friend_uuid, cell_id)
    values (new.friend_uuid, new.user_uuid, new.cell_id)
    on conflict (user_uuid, friend_uuid) do nothing;
    return new;
end;
$$ language plpgsql;

create or replace function public.delete_reciprocal_friend()
returns trigger as $$
begin
    delete from public.friends
    where user_uuid = old.friend_uuid and friend_uuid = old.user_uuid;
    return old;
end;
$$ language plpgsql;

create trigger create_reciprocal_friend_trigger
    after insert on public.friends
    for each row
    execute function public.create_reciprocal_friend();
create trigger delete_reciprocal_friend_trigger
    after delete on public.friends
    for each row
    execute function public.delete_reciprocal_friend();
