"""Embedding repository for data access."""

from typing import Any, cast
from uuid import UUID

from config.database import supabase
from config.settings import settings
from schemas.db import DBEmbeddingUserPost


def create_embedding(
    user_post_uuid: UUID, embedding: list[float]
) -> DBEmbeddingUserPost:
    embedding_data: dict[str, Any] = {
        "user_post_uuid": str(user_post_uuid),
        "embedding": embedding,
    }
    response = supabase.from_("embedding_user_posts").insert(embedding_data).execute()
    data = cast(list[dict[str, Any]], response.data)
    return DBEmbeddingUserPost(**data[0])


def find_similar_posts(
    query_embedding: list[float],
    match_count: int | None = None,
    threshold: float | None = None,
) -> list[DBEmbeddingUserPost]:
    if match_count is None:
        match_count = settings.CODAMA_MAX_COUNT - settings.CODAMA_AI_COUNT
    if threshold is None:
        threshold = settings.CODAMA_THRESHOLD
    response = supabase.rpc(
        "find_similar_posts",
        {
            "query_embedding": query_embedding,
            "match_count": match_count,
            "threshold": threshold,
        },
    ).execute()
    data = cast(list[dict[str, Any]], response.data)
    return [DBEmbeddingUserPost(**item) for item in data]
