from typing import Any, cast

import geohash
from shapely import wkb
from shapely.geometry import Point

from config.settings import settings
from infrastructure.clients.maps_client import maps_client


def encode_geo_hash(lat: float, lon: float) -> str:
    """緯度経度をジオハッシュにエンコード"""
    return str(geohash.encode(lat, lon, settings.GEO_HASH_PRECISION))


def decode_geo_hash(geo_hash: str) -> tuple[float, float]:
    """ジオハッシュを緯度経度にデコード"""
    pos = geohash.decode(geo_hash)
    return float(pos[0]), float(pos[1])


def decode_wkt_location(location_wkt: str) -> tuple[float, float]:
    """WKT形式の位置情報文字列を緯度経度のタプルにパース"""
    # WKT文字列をPointオブジェクトに変換
    point = cast(Point, wkb.loads(location_wkt, hex=True))
    # 緯度経度の順で返却（xy[1]が緯度、xy[0]が経度）
    lat = float(point.xy[1][0])
    lon = float(point.xy[0][0])
    return lat, lon


def encode_wkt_location(lat: float, lon: float) -> str:
    """緯度経度をWKT形式の位置情報文字列に変換"""
    result = wkb.dumps(Point(lon, lat), hex=True, srid=4326)
    return str(result)


def get_area_name_from_geocode(lat: float, lon: float) -> str | None:
    """Google Mapsのジオコーディングからエリア名を取得"""
    # 緯度経度から住所情報を逆引き
    geo_code = maps_client.gmaps.reverse_geocode((lat, lon), language="ja")
    if not geo_code or len(geo_code) == 0:
        return None

    # 住所コンポーネントから県、市、区の情報を取得
    admin_area: str | None = None
    locality: str | None = None
    sublocality: str | None = None
    result: dict[str, Any] = geo_code[0]

    components: list[dict[str, Any]] = result.get("address_components", [])
    for component in components:
        types: list[str] = component.get("types", [])
        if "administrative_area_level_1" in types:
            admin_area = cast(str | None, component.get("short_name"))
        elif "locality" in types:
            locality = cast(str | None, component.get("short_name"))
        elif "sublocality_level_1" in types:
            sublocality = cast(str | None, component.get("short_name"))

    # 県、市、区を結合して返す
    if admin_area and locality:
        return f"{admin_area}{locality}{sublocality or ''}"
    return None
