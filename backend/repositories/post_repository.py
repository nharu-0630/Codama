from typing import Any, cast
from uuid import UUID

import geohash  # type: ignore
from config.database import supabase
from schemas.db import DBLLMPost, DBUserPost


def get_user_post_by_uuid(post_uuid: str) -> DBUserPost | None:
    """UUIDでユーザー投稿を取得"""
    # UUIDで投稿を検索
    post_response = (
        supabase.from_("user_posts")
        .select("*")
        .eq("uuid", post_uuid)
        .single()
        .execute()
    )
    if not post_response.data:
        return None
    # 取得したデータをDBUserPostモデルに変換
    data = cast(dict[str, Any], post_response.data)
    return DBUserPost(**data)


def get_llm_posts_by_user_post_uuid(user_post_uuid: str) -> list[DBLLMPost]:
    """ユーザー投稿のUUIDに紐づくLLM返信の一覧を取得"""
    # ユーザー投稿UUIDで検索
    response = (
        supabase.from_("llm_posts")
        .select("*")
        .eq("user_post_uuid", user_post_uuid)
        .execute()
    )
    # 取得したデータをDBLLMPostモデルのリストに変換
    data = cast(list[dict[str, Any]], response.data)
    return [DBLLMPost(**item) for item in data]


def get_user_posts_by_location(geo_hash: str) -> list[DBUserPost]:
    """ジオハッシュで指定した位置とその隣接8セル（合計9セル）の投稿一覧を取得"""
    # 中心のgeohashと隣接8セルのgeohashを取得
    neighbor_hashes = geohash.neighbors(geo_hash)  # type: ignore
    geo_hashes = [geo_hash] + neighbor_hashes  # type: ignore

    # 9つのgeohashの投稿を検索
    query = (
        supabase.from_("user_posts")
        .select("*, cells!inner(id, geo_hash)")
        .in_("cells.geo_hash", geo_hashes)  # type: ignore
    )

    posts = query.execute()

    # 取得したデータをDBUserPostモデルのリストに変換
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def get_user_posts_by_user_uuid(user_uuid: str) -> list[DBUserPost]:
    """ユーザーUUIDでそのユーザーの投稿一覧を取得"""
    # ユーザーUUIDで検索
    posts = (
        supabase.from_("user_posts").select("*").eq("user_uuid", user_uuid).execute()
    )
    # 取得したデータをDBUserPostモデルのリストに変換
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def get_user_posts_by_uuids(post_uuids: list[str]) -> list[DBUserPost]:
    """UUIDのリストで複数のユーザー投稿を取得"""
    if not post_uuids:
        return []
    # UUIDのリストで検索
    posts = supabase.from_("user_posts").select("*").in_("uuid", post_uuids).execute()
    # 取得したデータをDBUserPostモデルのリストに変換
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def create_user_post(
    content: str, cell_id: int, user_uuid: UUID, location_wkt: str
) -> DBUserPost:
    """新しいユーザー投稿を作成"""
    # 投稿データを構築
    post_data: dict[str, Any] = {
        "content": content,
        "cell_id": cell_id,
        "user_uuid": str(user_uuid),
        "location": location_wkt,
    }
    # データベースに投稿を挿入
    response = supabase.from_("user_posts").insert(post_data).execute()
    # 作成された投稿をDBUserPostモデルに変換して返却
    data = cast(list[dict[str, Any]], response.data)
    return DBUserPost(**data[0])


def get_user_posts_by_cell_ids_after_date(
    cell_ids: list[int], after_date: str
) -> list[DBUserPost]:
    """指定日時以降のセルIDに紐づく投稿を取得"""
    if not cell_ids:
        return []

    # セルIDと作成日時でフィルタリング
    posts = (
        supabase.from_("user_posts")
        .select("*")
        .in_("cell_id", cell_ids)
        .filter("created_at", "gt", after_date)
        .execute()
    )

    # 取得したデータをDBUserPostモデルのリストに変換
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def get_recent_user_posts_by_cell_ids(
    cell_ids: list[int], limit: int = 5
) -> list[DBUserPost]:
    """セルIDに紐づく最近の投稿を取得"""
    if not cell_ids:
        return []

    # セルIDでフィルタして作成日時の降順で取得
    posts = (
        supabase.from_("user_posts")
        .select("*")
        .in_("cell_id", cell_ids)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )

    # 取得したデータをDBUserPostモデルのリストに変換
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def create_llm_post(content: str, user_post_uuid: UUID, location_wkt: str) -> DBLLMPost:
    """新しいLLM返信を作成"""
    # 返信データを構築
    post_data: dict[str, Any] = {
        "content": content,
        "user_post_uuid": str(user_post_uuid),
        "location": location_wkt,
    }
    # データベースに返信を挿入
    response = supabase.from_("llm_posts").insert(post_data).execute()
    # 作成された返信をDBLLMPostモデルに変換して返却
    data = cast(list[dict[str, Any]], response.data)
    return DBLLMPost(**data[0])
