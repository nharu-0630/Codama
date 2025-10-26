from time import sleep

from fastapi import APIRouter, Depends, HTTPException

from config.settings import settings
from repositories.cell_repository import get_or_create_cell
from repositories.embedding_repository import create_embedding, find_similar_posts
from repositories.post_repository import (
    create_llm_post,
    create_user_post,
    get_user_post_by_uuid,
    get_user_posts_by_location,
    get_user_posts_by_user_uuid,
    get_user_posts_by_uuids,
    get_user_posts_with_replies,
)
from schemas.api import (
    APIArea,
    APICell,
    APIPost,
    CreatePostRequest,
    CreatePostResponse,
    PostsResponse,
)
from schemas.db import DBLLMPost, DBUserPost
from utils.auth import get_current_user
from utils.coordinates import add_random_offset
from utils.geo_hash import (
    decode_wkt_location,
    encode_geo_hash,
    encode_wkt_location,
)
from utils.post_embedding import generate_embedding
from utils.post_llm import generate_post

router = APIRouter(prefix="/posts", tags=["posts"])


def transform_post(post: DBUserPost, replies: list[DBLLMPost]) -> APIPost:
    """データベースモデルの投稿をAPIモデルに変換"""
    # area_nameをネストされたモデルから取得
    return APIPost(
        uuid=post.uuid,
        user_uuid=post.user_uuid,
        content=post.content,
        location=decode_wkt_location(post.location),
        area=APIArea(
            id=post.cells.areas.id,
            name=post.cells.areas.name,
        )
        if post.cells and post.cells.areas
        else None,
        cell=APICell(
            id=post.cells.id,
            geo_hash=post.cells.geo_hash,
            location=decode_wkt_location(post.cells.location),
        )
        if post.cells
        else None,
        created_at=post.created_at,
        replies=[
            APIPost(
                uuid=reply.uuid,
                content=reply.content,
                location=decode_wkt_location(reply.location),
                created_at=reply.created_at,
                replies=[],
            )
            for reply in replies
        ],
    )


@router.get("", response_model=PostsResponse, dependencies=[Depends(get_current_user)])
async def get_posts(lat: float, lon: float):
    """現在位置の投稿一覧を取得"""
    # 緯度経度からジオハッシュを生成
    geo_hash = encode_geo_hash(lat, lon)

    # ジオハッシュで投稿を検索
    db_posts = get_user_posts_by_location(geo_hash, settings.POSTS_FETCH_LIMIT)

    # 各投稿にLLM返信を含めてAPIモデルに変換
    posts_with_replies = get_user_posts_with_replies(db_posts)
    posts = [transform_post(post, replies) for post, replies in posts_with_replies]

    return PostsResponse(posts=posts)


@router.get(
    "/me", response_model=PostsResponse, dependencies=[Depends(get_current_user)]
)
async def get_my_posts(user=Depends(get_current_user)):  # type: ignore
    """自分の投稿一覧を取得"""
    # ユーザーUUIDで投稿を検索
    db_posts = get_user_posts_by_user_uuid(user.id)

    # 各投稿にLLM返信を含めてAPIモデルに変換
    posts_with_replies = get_user_posts_with_replies(db_posts)
    posts = [transform_post(post, replies) for post, replies in posts_with_replies]

    return PostsResponse(posts=posts)


@router.post("", response_model=CreatePostResponse)
async def create_post(
    request: CreatePostRequest,
    user=Depends(get_current_user),  # type: ignore
):
    """新しい投稿を作成"""
    # 座標からセルを取得または作成
    cell = get_or_create_cell(request.lat, request.lon)
    if not cell:
        raise HTTPException(status_code=404, detail="Cell could not be created")

    # プライバシー保護のため座標にランダムオフセットを追加
    location = add_random_offset(request.lat, request.lon)

    # ユーザー投稿を作成
    db_created_post = create_user_post(
        content=request.content,
        cell_id=cell.id,
        user_uuid=user.id,
        location_wkt=encode_wkt_location(location[0], location[1]),
    )

    # 投稿内容からembeddingを生成して保存
    embedding = await generate_embedding(request.content)
    create_embedding(user_post_uuid=db_created_post.uuid, embedding=embedding)

    # 類似投稿を検索
    db_similar_embeddings = find_similar_posts(query_embedding=embedding)
    similar_post_uuids = [str(emb.user_post_uuid) for emb in db_similar_embeddings]

    # 類似投稿が少ない場合はAI返信を生成
    generate_count = max(
        settings.CODAMA_MIN_COUNT - len(similar_post_uuids), settings.CODAMA_AI_COUNT
    )
    for _ in range(generate_count):
        # LLMで返信を生成
        llm_response = await generate_post(request.content, cell.area_id)
        if llm_response is None:
            continue

        # AI返信の位置にもランダムオフセットを追加
        llm_location = add_random_offset(request.lat, request.lon)
        create_llm_post(
            content=llm_response,
            user_post_uuid=db_created_post.uuid,
            location_wkt=encode_wkt_location(llm_location[0], llm_location[1]),
        )
        # レート制限を考慮して待機
        sleep(1)

    # 作成した投稿とその返信を再取得
    db_created_post_refreshed = get_user_post_by_uuid(str(db_created_post.uuid))
    if not db_created_post_refreshed:
        raise HTTPException(status_code=500, detail="Failed to retrieve created post")

    # 作成した投稿のLLM返信を取得
    created_post_with_replies = get_user_posts_with_replies([db_created_post_refreshed])
    if not created_post_with_replies:
        raise HTTPException(
            status_code=500, detail="Failed to retrieve created post replies"
        )
    created_post, created_replies = created_post_with_replies[0]

    # 類似投稿を取得してAPIモデルに変換
    db_similar_posts = get_user_posts_by_uuids(similar_post_uuids)
    similar_posts_with_replies = get_user_posts_with_replies(db_similar_posts)
    api_similar_posts = [
        transform_post(post, replies) for post, replies in similar_posts_with_replies
    ]

    # 作成した投稿と類似投稿を返却
    return CreatePostResponse(
        post=transform_post(created_post, created_replies),
        similar_posts=api_similar_posts,
    )
