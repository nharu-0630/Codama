"""Post routes."""

from time import sleep
from typing import Any

from config.database import supabase
from config.settings import settings
from fastapi import APIRouter, Depends, HTTPException
from repositories.post_repository import (
    get_post_raw_by_uuid,
    get_posts_raw_by_location,
    get_posts_raw_by_uuids,
)
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


def transform_post_data(post_data: dict[str, Any]) -> Post:
    """Transform raw post data into Post model."""
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


@router.get("", response_model=PostsResponse, dependencies=[Depends(get_current_user)])
async def get_posts(lat: float, lon: float):
    """Get posts for the current location."""
    geo_hash = encode_location(lat, lon)
    posts_raw = get_posts_raw_by_location(geo_hash)
    posts = [transform_post_data(post) for post in posts_raw]
    return PostsResponse(posts=posts)


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
            "threshold": settings.CODAMA_THRESHOLD,
        },
    ).execute()
    similar_post_uuids = [  # type: ignore
        str(record["user_post_uuid"])  # type: ignore
        for record in similar_posts.data  # type: ignore
    ]

    supabase.from_("embedding_user_posts").insert(embedding_record).execute()

    generate_count = min(
        settings.CODAMA_MIN_COUNT - len(similar_post_uuids), settings.CODAMA_AI_COUNT
    )
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

    # Get the created post with its data
    created_post_raw = get_post_raw_by_uuid(str(created_post.data[0]["uuid"]))  # type: ignore
    if not created_post_raw:
        raise HTTPException(status_code=500, detail="Failed to retrieve created post")

    # Get similar posts
    similar_posts_raw = get_posts_raw_by_uuids(similar_post_uuids)

    return CreatePostResponse(
        post=transform_post_data(created_post_raw),
        similar_posts=[transform_post_data(post) for post in similar_posts_raw],
    )
