from typing import Any, cast

from config.database import supabase
from schemas.db import DBCell


def get_cell_by_id(cell_id: int) -> DBCell | None:
    """IDでセルを取得"""
    # IDでセルを検索
    response = supabase.from_("cells").select("*").eq("id", cell_id).execute()
    if not response.data:
        return None
    # 取得したデータをDBCellモデルに変換
    data = cast(list[dict[str, Any]], response.data)
    return DBCell(**data[0])


def get_cell_by_geo_hash(geo_hash: str) -> DBCell | None:
    """ジオハッシュでセルを取得"""
    # ジオハッシュでセルを検索
    response = supabase.from_("cells").select("*").eq("geo_hash", geo_hash).execute()
    if not response.data:
        return None
    # 取得したデータをDBCellモデルに変換
    data = cast(list[dict[str, Any]], response.data)
    return DBCell(**data[0])


def get_cells_by_area_id(area_id: int) -> list[DBCell]:
    """エリアIDに紐づく全セルを取得"""
    # エリアIDでセルを検索
    response = supabase.from_("cells").select("*").eq("area_id", area_id).execute()
    # 取得したデータをDBCellモデルのリストに変換
    data = cast(list[dict[str, Any]], response.data)
    return [DBCell(**item) for item in data]


def create_cell(geo_hash: str, location_wkt: str, area_id: int) -> DBCell:
    """新しいセルを作成"""
    # セルデータを構築
    cell_data: dict[str, Any] = {
        "geo_hash": geo_hash,
        "location": location_wkt,
        "area_id": area_id,
    }
    # データベースにセルを挿入
    response = supabase.from_("cells").insert(cell_data).execute()
    # 作成されたセルをDBCellモデルに変換して返却
    data = cast(list[dict[str, Any]], response.data)
    return DBCell(**data[0])
