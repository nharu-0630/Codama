from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class PromptBase(BaseModel):
    id: int
    prompt: str
    area_id: int
    created_at: datetime


class UserPost(BaseModel):
    id: int
    content: str
    location: tuple[float, float]
    cell_id: int
    created_at: datetime


class LLMPost(BaseModel):
    id: int
    content: str
    location: tuple[float, float]
    user_post_id: int
    created_at: datetime


class Area(BaseModel):
    id: int
    name: str


class Cell(BaseModel):
    id: int
    geo_hash: str
    location: tuple[float, float]


class CurrentResponse(BaseModel):
    area: Area
    cell: Cell


class PostsResponse(BaseModel):
    user_posts: list[UserPost]
    llm_posts: list[LLMPost]


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
