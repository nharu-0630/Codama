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
