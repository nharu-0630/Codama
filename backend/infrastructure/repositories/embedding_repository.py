import json
from typing import Any, List, cast
from uuid import UUID

from config.settings import settings
from domain.entities import EmbeddingUserPost
from infrastructure.clients.database_client import database_client
from interfaces.embedding_repository import EmbeddingRepositoryInterface


class EmbeddingRepository(EmbeddingRepositoryInterface):
    """Embeddingリポジトリの実装"""

    def __init__(self):
        self.db_client = database_client
        self.settings = settings

    def create_embedding(
        self, user_post_uuid: UUID, embedding: List[float]
    ) -> EmbeddingUserPost:
        """投稿のembeddingベクトルを作成"""
        embedding_data: dict[str, Any] = {
            "user_post_uuid": str(user_post_uuid),
            "embedding": embedding,
        }
        response = (
            self.db_client.supabase.from_("embedding_user_posts")
            .insert(embedding_data)
            .execute()
        )
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        if isinstance(item["embedding"], str):
            item["embedding"] = json.loads(item["embedding"])
        return EmbeddingUserPost(
            id=item["id"],
            embedding=item["embedding"],
            user_post_uuid=item["user_post_uuid"],
            created_at=item["created_at"],
        )

    def find_similar_posts(
        self,
        query_embedding: List[float],
        match_count: int | None = None,
        threshold: float | None = None,
    ) -> List[EmbeddingUserPost]:
        """embeddingベクトルから類似投稿を検索"""
        if match_count is None:
            match_count = self.settings.CODAMA_MAX_COUNT - self.settings.CODAMA_AI_COUNT
        if threshold is None:
            threshold = self.settings.CODAMA_THRESHOLD

        response = self.db_client.supabase.rpc(
            "find_similar_posts",
            {
                "query_embedding": query_embedding,
                "match_count": match_count,
                "threshold": threshold,
            },
        ).execute()

        data = cast(list[dict[str, Any]], response.data)
        for item in data:
            if isinstance(item["embedding"], str):
                item["embedding"] = json.loads(item["embedding"])
        return [
            EmbeddingUserPost(
                id=item["id"],
                embedding=item["embedding"],
                user_post_uuid=item["user_post_uuid"],
                created_at=item["created_at"],
            )
            for item in data
        ]
