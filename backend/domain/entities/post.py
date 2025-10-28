from dataclasses import dataclass
from datetime import datetime
from uuid import UUID
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from domain.entities import Cell


@dataclass
class UserPost:
    """ユーザー投稿エンティティ"""
    id: int
    uuid: UUID
    content: str
    user_uuid: UUID
    cell_id: int
    location: str
    created_at: datetime
    cell: Optional["Cell"] = None


@dataclass
class LLMPost:
    """LLM返信エンティティ"""
    id: int
    uuid: UUID
    content: str
    user_post_uuid: UUID
    location: str
    created_at: datetime
    user_post: Optional["UserPost"] = None