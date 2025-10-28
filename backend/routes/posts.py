from time import sleep

from fastapi import APIRouter, Depends, HTTPException

from application.container import container
from config.settings import settings
from domain.entities import LLMPost, UserPost
from interfaces.cell_repository import CellRepositoryInterface
from interfaces.embedding_repository import EmbeddingRepositoryInterface
from interfaces.post_repository import PostRepositoryInterface
from schemas.api import (
    APIArea,
    APICell,
    APIPost,
    CreatePostRequest,
    CreatePostResponse,
    PostsResponse,
)
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


def transform_post(post: UserPost, replies: list["LLMPost"]) -> APIPost:
    """データベースモデルの投稿をAPIモデルに変換"""
    # cellとareaが設定されている場合は適切に変換
    api_area: APIArea | None = None
    api_cell: APICell | None = None

    if post.cell and post.cell.area:
        api_area = APIArea(
            id=post.cell.area.id,
            name=post.cell.area.name,
        )
        api_cell = APICell(
            id=post.cell.id,
            geo_hash=post.cell.geo_hash,
            location=decode_wkt_location(post.cell.location),
        )

    return APIPost(
        uuid=post.uuid,
        user_uuid=post.user_uuid,
        content=post.content,
        location=decode_wkt_location(post.location),
        area=api_area,
        cell=api_cell,
        created_at=post.created_at,
        replies=[
            APIPost(
                uuid=reply.uuid,
                user_uuid=None,  # LLM投稿にはuser_uuidがない
                content=reply.content,
                location=decode_wkt_location(reply.location),
                area=None,
                cell=None,
                created_at=reply.created_at,
                replies=[],
            )
            for reply in replies
        ],
    )


@router.get("", response_model=PostsResponse, dependencies=[Depends(get_current_user)])
async def get_posts(lat: float, lon: float):
    """現在位置の投稿一覧を取得"""
    # 依存性注入コンテナからリポジトリを取得
    post_repo: PostRepositoryInterface = container.resolve(PostRepositoryInterface)

    # 緯度経度からジオハッシュを生成
    geo_hash = encode_geo_hash(lat, lon)

    # ジオハッシュで投稿を検索
    db_posts = post_repo.get_user_posts_by_location(
        geo_hash, settings.POSTS_FETCH_LIMIT
    )

    # 各投稿の返信を取得してAPIモデルに変換
    post_uuids = [str(post.uuid) for post in db_posts]
    replies = post_repo.get_replies_for_posts(post_uuids)

    # 返信を投稿ごとにグループ化
    replies_by_post: dict[str, list[LLMPost]] = {}
    for reply in replies:
        reply_key = str(reply.user_post_uuid)
        if reply_key not in replies_by_post:
            replies_by_post[reply_key] = []
        replies_by_post[reply_key].append(reply)

    posts = [
        transform_post(post, replies_by_post.get(str(post.uuid), []))
        for post in db_posts
    ]

    return PostsResponse(posts=posts)


@router.get(
    "/me", response_model=PostsResponse, dependencies=[Depends(get_current_user)]
)
async def get_my_posts(user=Depends(get_current_user)):  # type: ignore
    """自分の投稿一覧を取得"""
    # 依存性注入コンテナからリポジトリを取得
    post_repo: PostRepositoryInterface = container.resolve(PostRepositoryInterface)

    # ユーザーUUIDで投稿を検索
    db_posts = post_repo.get_user_posts_by_user_uuid(user.id)

    # 各投稿の返信を取得してAPIモデルに変換
    post_uuids = [str(post.uuid) for post in db_posts]
    replies = post_repo.get_replies_for_posts(post_uuids)

    # 返信を投稿ごとにグループ化
    replies_by_post: dict[str, list[LLMPost]] = {}
    for reply in replies:
        reply_key = str(reply.user_post_uuid)
        if reply_key not in replies_by_post:
            replies_by_post[reply_key] = []
        replies_by_post[reply_key].append(reply)

    posts = [
        transform_post(post, replies_by_post.get(str(post.uuid), []))
        for post in db_posts
    ]

    return PostsResponse(posts=posts)


@router.post("", response_model=CreatePostResponse)
async def create_post(
    request: CreatePostRequest,
    user=Depends(get_current_user),  # type: ignore
):
    """新しい投稿を作成"""
    # 依存性注入コンテナからリポジトリを取得
    cell_repo: CellRepositoryInterface = container.resolve(CellRepositoryInterface)
    post_repo: PostRepositoryInterface = container.resolve(PostRepositoryInterface)
    embedding_repo: EmbeddingRepositoryInterface = container.resolve(
        EmbeddingRepositoryInterface
    )

    # 座標からセルを取得または作成
    cell = cell_repo.get_or_create_cell(request.lat, request.lon)
    if not cell:
        raise HTTPException(status_code=404, detail="Cell could not be created")

    # プライバシー保護のため座標にランダムオフセットを追加
    location = add_random_offset(request.lat, request.lon)

    # ユーザー投稿を作成
    db_created_post = post_repo.create_user_post(
        content=request.content,
        user_uuid=user.id,
        cell_id=cell.id,
        location_wkt=encode_wkt_location(location[0], location[1]),
    )

    # 投稿内容からembeddingを生成して保存
    embedding = await generate_embedding(request.content)
    embedding_repo.create_embedding(
        user_post_uuid=db_created_post.uuid, embedding=embedding
    )

    # 類似投稿を検索
    db_similar_embeddings = embedding_repo.find_similar_posts(query_embedding=embedding)
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
        post_repo.create_llm_post(
            content=llm_response,
            user_post_uuid=db_created_post.uuid,
            location_wkt=encode_wkt_location(llm_location[0], llm_location[1]),
        )
        # レート制限を考慮して待機
        sleep(1)

    # 作成した投稿とその返信を再取得
    db_created_post_refreshed = post_repo.get_user_post_by_uuid(
        str(db_created_post.uuid)
    )
    if not db_created_post_refreshed:
        raise HTTPException(status_code=500, detail="Failed to retrieve created post")

    # 作成した投稿のLLM返信を取得
    created_post = db_created_post_refreshed
    replies = post_repo.get_replies_for_posts([str(created_post.uuid)])
    created_replies = replies

    # 類似投稿を取得してAPIモデルに変換（返信付きで）
    db_similar_posts = post_repo.get_user_posts_by_uuids(similar_post_uuids)
    # 類似投稿の返信も取得
    similar_post_uuids_list = [str(post.uuid) for post in db_similar_posts]
    similar_replies = post_repo.get_replies_for_posts(similar_post_uuids_list)

    # 返信を投稿ごとにグループ化
    replies_by_post: dict[str, list[LLMPost]] = {}
    for reply in similar_replies:
        reply_key = str(reply.user_post_uuid)
        if reply_key not in replies_by_post:
            replies_by_post[reply_key] = []
        replies_by_post[reply_key].append(reply)

    similar_posts = [
        transform_post(post, replies_by_post.get(str(post.uuid), []))
        for post in db_similar_posts
    ]

    # 作成した投稿と類似投稿を返却
    return CreatePostResponse(
        post=transform_post(created_post, created_replies),
        similar_posts=similar_posts,
    )
