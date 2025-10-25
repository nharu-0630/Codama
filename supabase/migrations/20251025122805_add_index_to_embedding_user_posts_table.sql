create index on public.embedding_user_posts using hnsw (embedding vector.vector_ip_ops);

create or replace function public.find_similar_posts (
  query_embedding vector.vector (1536),
  match_count int,
  threshold float default 0.7
)
returns setof public.embedding_user_posts
language plpgsql
set search_path = public, vector
as $$
begin
  return query
  select *
  from public.embedding_user_posts
  where (1 - (embedding <#> query_embedding)) >= threshold
  order by embedding <#> query_embedding
  limit match_count;
end;
$$;
