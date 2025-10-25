"""Post routes."""

import asyncio
import threading
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
from utils.post_llm import generate_post

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
                id=post["uuid"],  # type: ignore
                content=post["content"],  # type: ignore
                location=decode_wkt_location(str(post["location"])),  # type: ignore
                created_at=post["created_at"],  # type: ignore
                cell=Cell(
                    id=post["cells"]["id"],  # type: ignore
                    geo_hash=post["cells"]["geo_hash"],  # type: ignore
                    location=decode_wkt_location(str(post["cells"]["location"])),  # type: ignore
                ),
                llm_post=LLMPost(
                    uuid=post["llm_posts"]["uuid"],  # type: ignore
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

    area_id = int(cell_response.data[0]["area_id"])  # type: ignore
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

    async def create_llm_post():
        llm_response = await generate_post(request.content, area_id)
        if llm_response is None:
            return
        llm_location = add_random_offset(request.lat, request.lon)
        llm_post: dict[str, Any] = {
            "content": llm_response,
            "user_post_uuid": created_post.data[0]["uuid"],  # type: ignore
            "location": encode_wkt_location(llm_location[0], llm_location[1]),
        }
        supabase.from_("llm_posts").insert(llm_post).execute()

    threading.Thread(target=lambda: asyncio.run(create_llm_post())).start()

    return CreatePostResponse(
        success=True,
        user_post_id=created_post.data[0]["id"],  # type: ignore
    )
