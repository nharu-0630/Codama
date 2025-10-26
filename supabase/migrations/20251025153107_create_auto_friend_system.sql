-- 24時間以内の投稿差分ペアを追跡するためのテーブル
create table if not exists public.user_post_pairs (
    id bigint primary key generated always as identity,
    user1_uuid uuid not null references auth.users on delete cascade,
    user2_uuid uuid not null references auth.users on delete cascade,
    user1_post_uuid uuid not null references public.user_posts(uuid) on delete cascade,
    user2_post_uuid uuid not null references public.user_posts(uuid) on delete cascade,
    cell_id bigint not null references public.cells(id) on delete cascade,
    user1_post_time timestamptz not null,
    user2_post_time timestamptz not null,
    created_at timestamptz default now(),
    
    -- 同じ投稿ペアの重複を防ぐ
    unique (user1_post_uuid, user2_post_uuid)
);

-- user_posts作成時に自動friend化をチェックする関数
create or replace function public.check_and_create_auto_friends()
returns trigger as $$
declare
    total_pairs_count integer;
    friend_exists boolean;
    candidate_post record;
    v_user1_uuid uuid;
    v_user2_uuid uuid;
    v_user1_post_uuid uuid;
    v_user2_post_uuid uuid;
    v_user1_post_time timestamptz;
    v_user2_post_time timestamptz;
begin
    -- 同じcellに投稿した他のユーザーを検索（24時間以内）
    for candidate_post in
        select uuid as post_uuid, user_uuid, created_at, cell_id
        from public.user_posts
        where cell_id = new.cell_id
        and user_uuid != new.user_uuid
        and abs(extract(epoch from (new.created_at - created_at))) / 3600.0 <= 24.0
    loop
        -- 既にfriend関係があるかチェック
        select exists(
            select 1 from public.friends
            where (user_uuid = new.user_uuid and friend_uuid = candidate_post.user_uuid)
            or (user_uuid = candidate_post.user_uuid and friend_uuid = new.user_uuid)
        ) into friend_exists;

        -- 既にfriend関係がある場合はスキップ
        if friend_exists then
            continue;
        end if;

        -- user1_uuid < user2_uuidの順序で統一してペアを記録
        if new.user_uuid < candidate_post.user_uuid then
            v_user1_uuid := new.user_uuid;
            v_user2_uuid := candidate_post.user_uuid;
            v_user1_post_uuid := new.uuid;
            v_user2_post_uuid := candidate_post.post_uuid;
            v_user1_post_time := new.created_at;
            v_user2_post_time := candidate_post.created_at;
        else
            v_user1_uuid := candidate_post.user_uuid;
            v_user2_uuid := new.user_uuid;
            v_user1_post_uuid := candidate_post.post_uuid;
            v_user2_post_uuid := new.uuid;
            v_user1_post_time := candidate_post.created_at;
            v_user2_post_time := new.created_at;
        end if;

        -- ペアを記録（重複は無視）
        insert into public.user_post_pairs
            (user1_uuid, user2_uuid, user1_post_uuid, user2_post_uuid,
             cell_id, user1_post_time, user2_post_time)
        values
            (v_user1_uuid, v_user2_uuid, v_user1_post_uuid, v_user2_post_uuid,
             new.cell_id, v_user1_post_time, v_user2_post_time)
        on conflict (user1_post_uuid, user2_post_uuid) do nothing;
        
        -- この2人の間でのペア総数をチェック（全てのセルを含む）
        select count(*) into total_pairs_count
        from public.user_post_pairs
        where user_post_pairs.user1_uuid = v_user1_uuid
        and user_post_pairs.user2_uuid = v_user2_uuid;
        
        -- 5回以上の条件を満たしたらfriend関係を作成
        if total_pairs_count >= 5 then
            -- friend関係を作成（reciprocal triggerが自動で逆方向も作成）
            insert into public.friends (user_uuid, friend_uuid, cell_id)
            values (new.user_uuid, candidate_post.user_uuid, new.cell_id)
            on conflict (user_uuid, friend_uuid) do nothing;
        end if;
    end loop;
    
    return new;
end;
$$ language plpgsql;

-- user_posts テーブルにトリガーを設定
create trigger auto_friend_trigger
    after insert on public.user_posts
    for each row
    execute function public.check_and_create_auto_friends();
