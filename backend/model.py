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
    cell_id: int
    created_at: datetime


class LLMPost(BaseModel):
    id: int
    content: str
    user_post_id: int
    created_at: datetime


class Area(BaseModel):
    id: int
    name: str


class Cell(BaseModel):
    id: int
    geo_hash: str
    location: tuple[float, float]


class Post(BaseModel):
    id: int
    content: str
    created_at: datetime
    cell: Optional[Cell] = None


class CurrentResponse(BaseModel):
    area: Area
    cell: Cell


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
