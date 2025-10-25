from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class APIArea(BaseModel):
    """API model for area information."""

    id: int
    name: str


class APICell(BaseModel):
    """API model for cell information."""

    id: int
    geo_hash: str
    location: tuple[float, float]  # (latitude, longitude)


class APIPost(BaseModel):
    """API model for post information (user or LLM posts)."""

    uuid: UUID
    content: str
    location: tuple[float, float]  # (latitude, longitude)
    replies: list["APIPost"] = []
    created_at: datetime


APIPost.update_forward_refs()  # type: ignore


class APIPrompt(BaseModel):
    """API model for prompt information."""

    id: int
    prompt: str
    area_id: int
    created_at: datetime


class CurrentResponse(BaseModel):
    """Response for current location endpoint."""

    area: APIArea
    cell: APICell


class PostsResponse(BaseModel):
    """Response for posts endpoint."""

    posts: list[APIPost]


class CreatePostResponse(BaseModel):
    """Response for creating a post."""

    post: APIPost
    similar_posts: list[APIPost]


class SignupResponse(BaseModel):
    """Response for signup endpoint."""

    access_token: str
    refresh_token: str
    user_id: str


class UpdatePromptResponse(BaseModel):
    """Response for updating prompts."""

    success: bool


class CreatePostRequest(BaseModel):
    """Request for creating a post."""

    content: str
    lat: float
    lon: float
