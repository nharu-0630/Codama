"""API schemas for the application."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class PromptBase(BaseModel):
    id: int
    prompt: str
    area_id: int
    created_at: datetime


class Post(BaseModel):
    uuid: UUID
    content: str
    location: tuple[float, float]
    replies: list["Post"] = []
    created_at: datetime


Post.update_forward_refs()  # type: ignore


class Cell(BaseModel):
    id: int
    geo_hash: str
    location: tuple[float, float]


class Area(BaseModel):
    id: int
    name: str


class CurrentResponse(BaseModel):
    area: Area
    cell: Cell


class PostsResponse(BaseModel):
    posts: list[Post]


class CreatePostRequest(BaseModel):
    content: str
    lat: float
    lon: float


class CreatePostResponse(BaseModel):
    post: Post
    similars: list[Post]


class SignupResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str


class UpdatePromptResponse(BaseModel):
    success: bool
