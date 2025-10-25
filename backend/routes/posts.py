"""Post routes."""

import asyncio
import threading
from time import sleep
from typing import Any

from config.database import supabase
from config.settings import settings
from fastapi import APIRouter, Depends, HTTPException
from schemas.model import (
    CreatePostRequest,
    CreatePostResponse,
    Post,
    PostsResponse,
)
from utils.auth import get_current_user
from utils.coordinates import add_random_offset
from utils.geohash import (
    decode_wkt_location,
    encode_location,
    encode_wkt_location,
    get_or_create_cell,
)
from utils.post_embedding import generate_embedding
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
        posts=[
            Post(
                uuid=post["uuid"],  # type: ignore
                content=post["content"],  # type: ignore
                location=decode_wkt_location(str(post["location"])),  # type: ignore
                created_at=post["created_at"],  # type: ignore
                replies=[
                    Post(
                        uuid=reply["uuid"],  # type: ignore
                        content=reply["content"],  # type: ignore
                        location=decode_wkt_location(str(reply["location"])),  # type: ignore
                        created_at=reply["created_at"],  # type: ignore
                        replies=[],
                    )
                    for reply in post.get("llm_posts", [])  # type: ignore
                ],
            )
            for post in posts.data
        ],
    )

@router.get("/{post_uuid}", response_model=Post, dependencies=[Depends(get_current_user)])
async def get_post(post_uuid: str):
    """Get a specific post by UUID."""
    post_response = (
        supabase.from_("user_posts")
        .select(
            "*, llm_posts(id, content, location, created_at)"
        )
        .eq("uuid", post_uuid)
        .single()
        .execute()
    )
    post_data = post_response.data
    if not post_data:
        raise HTTPException(status_code=404, detail="Post not found")

    return Post(
        uuid=post_data["uuid"],  # type: ignore
        content=post_data["content"],  # type: ignore
        location=decode_wkt_location(str(post_data["location"])),  # type: ignore
        created_at=post_data["created_at"],  # type: ignore
        replies=[
            Post(
                uuid=reply["uuid"],  # type: ignore
                content=reply["content"],  # type: ignore
                location=decode_wkt_location(str(reply["location"])),  # type: ignore
                created_at=reply["created_at"],  # type: ignore
                replies=[],
            )
            for reply in post_data.get("llm_posts", [])  # type: ignore
        ],
    )

@router.post("", response_model=CreatePostResponse)
async def create_post(
    request: CreatePostRequest,
    user=Depends(get_current_user),  # type: ignore
):
    """Create a new post."""
    cell_data = get_or_create_cell(request.lat, request.lon)

    area_id = int(cell_data["area_id"])  # type: ignore
    location = add_random_offset(request.lat, request.lon)
    cell_id = int(cell_data["id"])  # type: ignore
    new_post: dict[str, Any] = {
        "content": request.content,
        "cell_id": cell_id,
        "user_uuid": user.id,
        "location": encode_wkt_location(location[0], location[1]),
    }
    created_post = supabase.from_("user_posts").insert(new_post).execute()
    if not created_post.data:
        raise HTTPException(status_code=500, detail="Failed to create post")

    embedding = await generate_embedding(request.content)
    embedding_record: dict[str, Any] = {
        "user_post_uuid": created_post.data[0]["uuid"],  # type: ignore
        "embedding": embedding,
    }

    similar_posts = supabase.rpc(
        "find_similar_posts",
        {
            "query_embedding": embedding,
            "match_count": settings.CODAMA_MAX_COUNT - settings.CODAMA_AI_COUNT,
        },
    ).execute()
    similar_post_uuids = [  # type: ignore
        str(record["user_post_uuid"])  # type: ignore
        for record in similar_posts.data  # type: ignore
    ]

    generate_count = min(
        settings.CODAMA_MIN_COUNT - len(similar_post_uuids), settings.CODAMA_AI_COUNT
    )
    async def generate_posts():
        for _ in range(generate_count):
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
            sleep(1)

    threading.Thread(target=lambda: asyncio.run(generate_posts())).start()
    supabase.from_("embedding_user_posts").insert(embedding_record).execute()


    return CreatePostResponse(
        replies=
    )
