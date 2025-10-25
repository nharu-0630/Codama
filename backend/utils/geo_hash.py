from typing import Any

import pygeohash as gh  # type: ignore
from config.database import gmaps
from config.settings import settings
from fastapi import HTTPException
from repositories.area_repository import get_all_areas
from repositories.cell_repository import create_cell, get_cell_by_geo_hash
from shapely import wkb
from shapely.geometry import Point


def encode_geo_hash(lat: float, lon: float) -> str:
    """緯度経度をジオハッシュにエンコード"""
    return gh.encode(lat, lon, precision=settings.GEO_HASH_PRECISION)


def decode_geo_hash(geo_hash: str) -> tuple[float, float]:
    """ジオハッシュを緯度経度にデコード"""
    pos = gh.decode(geo_hash)
    return pos.latitude, pos.longitude


def get_or_create_cell(lat: float, lon: float) -> dict[str, Any]:
    """指定された座標のセルを取得、存在しない場合は新規作成"""
    # 緯度経度からジオハッシュを生成
    geo_hash = encode_geo_hash(lat, lon)
    center_pos = gh.decode(geo_hash)

    # 既存のセルを検索
    db_cell = get_cell_by_geo_hash(geo_hash)

    if not db_cell:
        # Google Mapsからエリア名を取得
        area_name = _get_area_name_from_geocode(lat, lon)
        if not area_name:
            raise HTTPException(status_code=404, detail="Area not found from geocode")

        # エリア名からエリア情報を検索
        db_areas = get_all_areas()
        db_area = next((area for area in db_areas if area.name == area_name), None)
        if not db_area:
            raise HTTPException(status_code=404, detail="Area not found")

        # 新しいセルを作成
        location_wkt = f"POINT({center_pos.longitude} {center_pos.latitude})"
        db_cell = create_cell(
            geo_hash=geo_hash, location_wkt=location_wkt, area_id=db_area.id
        )

    # 後方互換性のため辞書形式で返却
    return {
        "id": db_cell.id,
        "geo_hash": db_cell.geo_hash,
        "area_id": db_cell.area_id,
        "created_at": db_cell.created_at,
        "location": db_cell.location,
    }


def decode_wkt_location(location_wkt: str) -> tuple[float, float]:
    """WKT形式の位置情報文字列を緯度経度のタプルにパース"""
    # WKT文字列をPointオブジェクトに変換
    point = wkb.loads(location_wkt, hex=True)
    # 緯度経度の順で返却（xy[1]が緯度、xy[0]が経度）
    return point.xy[1][0], point.xy[0][0]  # type: ignore


def encode_wkt_location(lat: float, lon: float) -> str:
    """緯度経度をWKT形式の位置情報文字列に変換"""
    return wkb.dumps(Point(lon, lat), hex=True, srid=4326)  # type: ignore


def _get_area_name_from_geocode(lat: float, lon: float) -> str | None:
    """Google Mapsのジオコーディングからエリア名を取得"""
    # 緯度経度から住所情報を逆引き
    geo_code = gmaps.reverse_geocode((lat, lon), language="ja")  # type: ignore
    if geo_code and len(geo_code) > 0:  # type: ignore
        # 住所コンポーネントからsublocality_level_1（区レベル）を検索
        for component in geo_code[0].get("address_components", []):  # type: ignore
            if "sublocality_level_1" in component.get("types", []):  # type: ignore
                return str(component.get("short_name"))  # type: ignore
    return None
