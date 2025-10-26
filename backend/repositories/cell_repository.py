from typing import Any, cast

from config.database import supabase
from repositories.area_repository import create_area, get_area_by_name
from schemas.db import DBCell
from utils.geo_hash import decode_geo_hash, encode_geo_hash, get_area_name_from_geocode


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


def get_or_create_cell(lat: float, lon: float) -> DBCell | None:
    """指定された座標のセルを取得、存在しない場合は新規作成"""
    # 緯度経度からジオハッシュを生成
    geo_hash = encode_geo_hash(lat, lon)
    center_lat, center_lon = decode_geo_hash(geo_hash)

    # 既存のセルを検索
    db_cell = get_cell_by_geo_hash(geo_hash)
    if db_cell:
        return db_cell

    # Google Mapsからエリア名を取得
    area_name = get_area_name_from_geocode(lat, lon)
    if not area_name:
        return None

    # エリア名からエリア情報を検索
    db_area = get_area_by_name(area_name)
    if not db_area:
        # エリアが存在しない場合は新規作成
        db_area = create_area(name=area_name)

    # 新しいセルを作成
    location_wkt = f"POINT({center_lon} {center_lat})"
    db_cell = create_cell(
        geo_hash=geo_hash, location_wkt=location_wkt, area_id=db_area.id
    )
    return db_cell


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
