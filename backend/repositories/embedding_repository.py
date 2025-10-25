import json
from typing import Any, cast
from uuid import UUID

from config.database import supabase
from config.settings import settings
from schemas.db import DBEmbeddingUserPost


def create_embedding(
    user_post_uuid: UUID, embedding: list[float]
) -> DBEmbeddingUserPost:
    """投稿のembeddingベクトルを作成"""
    # embeddingデータを構築
    embedding_data: dict[str, Any] = {
        "user_post_uuid": str(user_post_uuid),
        "embedding": embedding,
    }
    # データベースにembeddingを挿入
    response = supabase.from_("embedding_user_posts").insert(embedding_data).execute()
    # 作成されたembeddingをDBEmbeddingUserPostモデルに変換して返却
    data = cast(list[dict[str, Any]], response.data)
    # embeddingが文字列の場合はリストに変換
    if isinstance(data[0]["embedding"], str):
        data[0]["embedding"] = json.loads(data[0]["embedding"])
    return DBEmbeddingUserPost(**data[0])


def find_similar_posts(
    query_embedding: list[float],
    match_count: int | None = None,
    threshold: float | None = None,
) -> list[DBEmbeddingUserPost]:
    """embeddingベクトルから類似投稿を検索"""
    # デフォルト値を設定
    if match_count is None:
        match_count = settings.CODAMA_MAX_COUNT - settings.CODAMA_AI_COUNT
    if threshold is None:
        threshold = settings.CODAMA_THRESHOLD

    # データベースの関数を呼び出して類似投稿を検索
    response = supabase.rpc(
        "find_similar_posts",
        {
            "query_embedding": query_embedding,
            "match_count": match_count,
            "threshold": threshold,
        },
    ).execute()

    # 取得したデータをDBEmbeddingUserPostモデルのリストに変換
    data = cast(list[dict[str, Any]], response.data)
    # embeddingが文字列の場合はリストに変換
    for item in data:
        if isinstance(item["embedding"], str):
            item["embedding"] = json.loads(item["embedding"])
    return [DBEmbeddingUserPost(**item) for item in data]
