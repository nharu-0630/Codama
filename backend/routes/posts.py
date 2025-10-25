"""Post routes."""

from time import sleep

from config.settings import settings
from fastapi import APIRouter, Depends, HTTPException
from repositories.embedding_repository import create_embedding, find_similar_posts
from repositories.post_repository import (
    create_llm_post,
    create_user_post,
    get_llm_posts_by_user_post_uuid,
    get_user_post_by_uuid,
    get_user_posts_by_location,
    get_user_posts_by_uuids,
)
from schemas.api import APIPost, CreatePostRequest, CreatePostResponse, PostsResponse
from schemas.db import DBLLMPost, DBUserPost
from utils.auth import get_current_user
from utils.coordinates import add_random_offset
from backend.utils.geo_hash import (
    decode_wkt_location,
    encode_geo_hash,
    encode_wkt_location,
    get_or_create_cell,
)
from utils.post_embedding import generate_embedding
from utils.post_llm import generate_post

router = APIRouter(prefix="/posts", tags=["posts"])


def transform_db_post_to_api(
    db_post: DBUserPost, db_llm_posts: list[DBLLMPost]
) -> APIPost:
    """Transform DB post models to API post model."""
    return APIPost(
        uuid=db_post.uuid,
        content=db_post.content,
        location=decode_wkt_location(db_post.location),
        created_at=db_post.created_at,
        replies=[
            APIPost(
                uuid=llm_post.uuid,
                content=llm_post.content,
                location=decode_wkt_location(llm_post.location),
                created_at=llm_post.created_at,
                replies=[],
            )
            for llm_post in db_llm_posts
        ],
    )


@router.get("", response_model=PostsResponse, dependencies=[Depends(get_current_user)])
async def get_posts(lat: float, lon: float):
    """Get posts for the current location."""
    geo_hash = encode_geo_hash(lat, lon)
    db_posts = get_user_posts_by_location(geo_hash)

    api_posts: list[APIPost] = []
    for db_post in db_posts:
        db_llm_posts = get_llm_posts_by_user_post_uuid(str(db_post.uuid))
        api_posts.append(transform_db_post_to_api(db_post, db_llm_posts))

    return PostsResponse(posts=api_posts)


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

    # Create user post
    db_created_post = create_user_post(
        content=request.content,
        cell_id=cell_id,
        user_uuid=user.id,
        location_wkt=encode_wkt_location(location[0], location[1]),
    )

    # Generate and store embedding
    embedding = await generate_embedding(request.content)
    create_embedding(user_post_uuid=db_created_post.uuid, embedding=embedding)

    # Find similar posts
    db_similar_embeddings = find_similar_posts(query_embedding=embedding)
    similar_post_uuids = [str(emb.user_post_uuid) for emb in db_similar_embeddings]

    # Generate AI responses if needed
    generate_count = min(
        settings.CODAMA_MIN_COUNT - len(similar_post_uuids), settings.CODAMA_AI_COUNT
    )
    for _ in range(generate_count):
        llm_response = await generate_post(request.content, area_id)
        if llm_response is None:
            continue
        llm_location = add_random_offset(request.lat, request.lon)
        create_llm_post(
            content=llm_response,
            user_post_uuid=db_created_post.uuid,
            location_wkt=encode_wkt_location(llm_location[0], llm_location[1]),
        )
        sleep(1)

    # Get the created post with its replies
    db_created_post_refreshed = get_user_post_by_uuid(str(db_created_post.uuid))
    if not db_created_post_refreshed:
        raise HTTPException(status_code=500, detail="Failed to retrieve created post")

    db_created_llm_posts = get_llm_posts_by_user_post_uuid(str(db_created_post.uuid))

    # Get similar posts
    db_similar_posts = get_user_posts_by_uuids(similar_post_uuids)
    api_similar_posts: list[APIPost] = []
    for db_post in db_similar_posts:
        db_llm_posts = get_llm_posts_by_user_post_uuid(str(db_post.uuid))
        api_similar_posts.append(transform_db_post_to_api(db_post, db_llm_posts))

    return CreatePostResponse(
        post=transform_db_post_to_api(db_created_post_refreshed, db_created_llm_posts),
        similar_posts=api_similar_posts,
    )
