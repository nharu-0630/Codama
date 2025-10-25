"""
Pydantic schemas for API request/response models.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class PostCreate(BaseModel):
    """Schema for creating a new post."""

    username: str = Field(..., min_length=1, max_length=50, description="Username of the poster")
    text: str = Field(..., min_length=1, max_length=500, description="Post content")
    latitude: float = Field(..., ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude coordinate")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "username": "john_doe",
                    "text": "Hello from Tokyo!",
                    "latitude": 35.6812,
                    "longitude": 139.7671,
                }
            ]
        }
    }


class PostResponse(BaseModel):
    """Schema for post response."""

    id: UUID = Field(..., description="Unique identifier for the post")
    username: str = Field(..., description="Username of the poster")
    text: str = Field(..., description="Post content")
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    created_at: datetime = Field(..., description="Timestamp when the post was created")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "id": "123e4567-e89b-12d3-a456-426614174000",
                    "username": "john_doe",
                    "text": "Hello from Tokyo!",
                    "latitude": 35.6812,
                    "longitude": 139.7671,
                    "created_at": "2025-10-25T12:00:00Z",
                }
            ]
        }
    }


class NearbyPostsResponse(BaseModel):
    """Schema for nearby posts response."""

    posts: list[PostResponse] = Field(..., description="List of nearby posts")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "posts": [
                        {
                            "id": "123e4567-e89b-12d3-a456-426614174000",
                            "username": "john_doe",
                            "text": "Hello from Tokyo!",
                            "latitude": 35.6812,
                            "longitude": 139.7671,
                            "created_at": "2025-10-25T12:00:00Z",
                        }
                    ]
                }
            ]
        }
    }
