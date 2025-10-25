"""API schemas for the application."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class DBArea(BaseModel):
    """Database model for areas table."""

    id: int
    name: str
    created_at: datetime


class DBCell(BaseModel):
    """Database model for cells table."""

    id: int
    geo_hash: str
    location: str  # PostGIS geography(POINT) as WKT string
    area_id: int
    created_at: datetime


class DBUserPost(BaseModel):
    """Database model for user_posts table."""

    id: int
    uuid: UUID
    content: str
    user_uuid: UUID
    cell_id: int
    location: str  # PostGIS geography(POINT) as WKT string
    created_at: datetime


class DBLLMPost(BaseModel):
    """Database model for llm_posts table."""

    id: int
    uuid: UUID
    content: str
    user_post_uuid: UUID
    location: str  # PostGIS geography(POINT) as WKT string
    created_at: datetime


class DBPrompt(BaseModel):
    """Database model for prompts table."""

    id: int
    prompt: str
    area_id: int
    created_at: datetime


class DBEmbeddingUserPost(BaseModel):
    """Database model for embedding_user_posts table."""

    id: int
    embedding: list[float]  # vector(1536)
    user_post_uuid: UUID
    created_at: datetime


class DBFriend(BaseModel):
    """Database model for friends table."""

    id: int
    user_uuid: UUID
    friend_uuid: UUID
    cell_id: int
    created_at: datetime
