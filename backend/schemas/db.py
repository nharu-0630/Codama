from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class DBArea(BaseModel):
    """areasテーブルのデータベースモデル"""

    id: int
    name: str
    created_at: datetime


class DBCell(BaseModel):
    """cellsテーブルのデータベースモデル"""

    id: int
    geo_hash: str
    location: str
    area_id: int
    created_at: datetime
    areas: "DBArea | None" = None


class DBUserPost(BaseModel):
    """user_postsテーブルのデータベースモデル"""

    id: int
    uuid: UUID
    content: str
    user_uuid: UUID
    cell_id: int
    location: str
    created_at: datetime
    cells: "DBCell | None" = None


class DBLLMPost(BaseModel):
    """llm_postsテーブルのデータベースモデル"""

    id: int
    uuid: UUID
    content: str
    user_post_uuid: UUID
    location: str
    created_at: datetime
    user_posts: "DBUserPostForLLMReply | None" = None


class DBUserPostForLLMReply(BaseModel):
    """LLM返信用のuser_postsテーブルのデータベースモデル（cell情報のみ）"""

    cell_id: int
    cells: "DBCell | None" = None


class DBPrompt(BaseModel):
    """promptsテーブルのデータベースモデル"""

    id: int
    prompt: str
    area_id: int
    created_at: datetime


class DBEmbeddingUserPost(BaseModel):
    """embedding_user_postsテーブルのデータベースモデル"""

    id: int
    embedding: list[float]
    user_post_uuid: UUID
    created_at: datetime


class DBFriend(BaseModel):
    """friendsテーブルのデータベースモデル"""

    id: int
    user_uuid: UUID
    friend_uuid: UUID
    cell_id: int
    created_at: datetime


# Forward referencesを解決
DBCell.model_rebuild()
DBUserPost.model_rebuild()
DBLLMPost.model_rebuild()
DBUserPostForLLMReply.model_rebuild()
