from typing import Any, cast

from config.database import supabase
from schemas.db import DBArea


def get_all_areas() -> list[DBArea]:
    """全エリアの一覧を取得"""
    # 全エリアを検索
    response = supabase.from_("areas").select("*").execute()
    # 取得したデータをDBAreaモデルのリストに変換
    data = cast(list[dict[str, Any]], response.data)
    return [DBArea(**item) for item in data]


def get_area_by_id(area_id: int) -> DBArea | None:
    """IDでエリアを取得"""
    # IDでエリアを検索
    response = supabase.from_("areas").select("*").eq("id", area_id).execute()
    if not response.data:
        return None
    # 取得したデータをDBAreaモデルに変換
    data = cast(list[dict[str, Any]], response.data)
    return DBArea(**data[0])


def get_area_by_name(name: str) -> DBArea | None:
    """名前でエリアを取得"""
    # 名前でエリアを検索
    response = supabase.from_("areas").select("*").eq("name", name).execute()
    if not response.data:
        return None
    # 取得したデータをDBAreaモデルに変換
    data = cast(list[dict[str, Any]], response.data)
    return DBArea(**data[0])


def create_area(name: str) -> DBArea:
    """新しいエリアを作成"""
    # エリアデータを構築
    area_data: dict[str, Any] = {
        "name": name,
    }
    # データベースにエリアを挿入
    response = supabase.from_("areas").insert(area_data).execute()
    # 作成されたエリアをDBAreaモデルに変換して返却
    data = cast(list[dict[str, Any]], response.data)
    return DBArea(**data[0])
