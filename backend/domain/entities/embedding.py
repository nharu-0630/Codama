from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass
class EmbeddingUserPost:
    """埋め込みユーザー投稿エンティティ"""

    id: int
    embedding: list[float]
    user_post_uuid: UUID
    created_at: datetime
