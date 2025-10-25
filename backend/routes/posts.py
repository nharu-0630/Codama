"""Post routes."""

from typing import Any

from fastapi import APIRouter, Depends, HTTPException

from config.database import supabase
from schemas.model import (
    Cell,
    CreatePostRequest,
    CreatePostResponse,
    LLMPost,
    PostsResponse,
    UserPost,
)
from utils.auth import get_current_user
from utils.coordinates import add_random_offset
from utils.geohash import decode_wkt_location, encode_location, encode_wkt_location

router = APIRouter(prefix="/posts", tags=["posts"])


@router.get("", response_model=PostsResponse, dependencies=[Depends(get_current_user)])
async def get_posts(lat: float, lon: float):
    """Get posts for the current location."""
    geo_hash = encode_location(lat, lon)
    posts = (
        supabase.from_("user_posts")
        .select(
            "*, cells!inner(id, geo_hash, location), llm_posts(id, content, location, created_at)"
        )
        .like("cells.geo_hash", f"{geo_hash}%")
        .execute()
    )
    return PostsResponse(
        user_posts=[
            UserPost(
                id=post["id"],  # type: ignore
                content=post["content"],  # type: ignore
                location=decode_wkt_location(str(post["location"])),  # type: ignore
                created_at=post["created_at"],  # type: ignore
                cell=Cell(
                    id=post["cells"]["id"],  # type: ignore
                    geo_hash=post["cells"]["geo_hash"],  # type: ignore
                    location=decode_wkt_location(str(post["cells"]["location"])),  # type: ignore
                ),
                llm_post=LLMPost(
                    id=post["llm_posts"]["id"],  # type: ignore
                    content=post["llm_posts"]["content"],  # type: ignore
                    location=decode_wkt_location(str(post["llm_posts"]["location"])),  # type: ignore
                    created_at=post["llm_posts"]["created_at"],  # type: ignore
                )
                if post.get("llm_posts")  # type: ignore
                else None,
            )
            for post in posts.data
        ],
    )


@router.post("", response_model=CreatePostResponse)
async def create_post(
    request: CreatePostRequest,
    user=Depends(get_current_user),  # type: ignore
):
    """Create a new post."""
    geo_hash = encode_location(request.lat, request.lon)
    cell_response = (
        supabase.from_("cells").select("*").like("geo_hash", f"{geo_hash}%").execute()
    )
    if not cell_response.data:
        raise HTTPException(status_code=404, detail="Cell not found")

    location = add_random_offset(request.lat, request.lon)
    cell_id = int(cell_response.data[0]["id"])  # type: ignore
    new_post: dict[str, Any] = {
        "content": request.content,
        "cell_id": cell_id,
        "user_uuid": user.id,
        "location": encode_wkt_location(location[0], location[1]),
    }
    created_post = supabase.from_("user_posts").insert(new_post).execute()
    if not created_post.data:
        raise HTTPException(status_code=500, detail="Failed to create post")

    return CreatePostResponse(
        success=True,
        user_post_id=created_post.data[0]["id"],  # type: ignore
    )
