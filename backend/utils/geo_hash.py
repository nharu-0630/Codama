import pygeohash as gh  # type: ignore
from shapely import wkb
from shapely.geometry import Point

from config.database import gmaps
from config.settings import settings


def encode_geo_hash(lat: float, lon: float) -> str:
    """緯度経度をジオハッシュにエンコード"""
    return gh.encode(lat, lon, precision=settings.GEO_HASH_PRECISION)


def decode_geo_hash(geo_hash: str) -> tuple[float, float]:
    """ジオハッシュを緯度経度にデコード"""
    pos = gh.decode(geo_hash)
    return pos.latitude, pos.longitude


def decode_wkt_location(location_wkt: str) -> tuple[float, float]:
    """WKT形式の位置情報文字列を緯度経度のタプルにパース"""
    # WKT文字列をPointオブジェクトに変換
    point = wkb.loads(location_wkt, hex=True)
    # 緯度経度の順で返却（xy[1]が緯度、xy[0]が経度）
    return point.xy[1][0], point.xy[0][0]  # type: ignore


def encode_wkt_location(lat: float, lon: float) -> str:
    """緯度経度をWKT形式の位置情報文字列に変換"""
    return wkb.dumps(Point(lon, lat), hex=True, srid=4326)  # type: ignore


def get_area_name_from_geocode(lat: float, lon: float) -> str | None:
    """Google Mapsのジオコーディングからエリア名を取得"""
    # 緯度経度から住所情報を逆引き
    geo_code = gmaps.reverse_geocode((lat, lon), language="ja")  # type: ignore
    if geo_code and len(geo_code) > 0:  # type: ignore
        # 住所コンポーネントから県、市、区の情報を取得
        admin_area = None
        locality = None
        sublocality = None
        for component in geo_code[0].get("address_components", []):  # type: ignore
            types = component.get("types", [])  # type: ignore
            if "administrative_area_level_1" in types:
                admin_area = component.get("short_name")  # type: ignore
            elif "locality" in types:
                locality = component.get("short_name")  # type: ignore
            elif "sublocality_level_1" in types:
                sublocality = component.get("short_name")  # type: ignore
        # 県、市、区を結合して返す
        if admin_area and locality and sublocality:
            return f"{admin_area}{locality}{sublocality}"
    return None
