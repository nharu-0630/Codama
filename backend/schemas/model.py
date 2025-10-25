"""API schemas for the application."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class PromptBase(BaseModel):
    id: int
    prompt: str
    area_id: int
    created_at: datetime


class BasePost(BaseModel):
    uuid: UUID
    content: str
    location: tuple[float, float]
    created_at: datetime


class LLMPost(BasePost):
    pass


class Cell(BaseModel):
    id: int
    geo_hash: str
    location: tuple[float, float]


class UserPost(BasePost):
    llm_post: Optional[LLMPost]


class Area(BaseModel):
    id: int
    name: str


class CurrentResponse(BaseModel):
    area: Area
    cell: Cell


class PostsResponse(BaseModel):
    user_posts: list[UserPost]


class CreatePostRequest(BaseModel):
    content: str
    lat: float
    lon: float


class CreatePostResponse(BaseModel):
    success: bool
    user_post_id: int


class SignupResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str


class UpdatePromptResponse(BaseModel):
    success: bool
