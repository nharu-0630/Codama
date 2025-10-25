create index on public.embedding_user_posts using hnsw (embedding vector_ip_ops);

create or replace function public.find_similar_posts (
  query_embedding vector (1536),
  match_count int
)
returns setof public.embedding_user_posts
language plpgsql
as $$
begin
  return query
  select *
  from public.embedding_user_posts
  order by embedding <#> query_embedding
  limit match_count;
end;
$$;