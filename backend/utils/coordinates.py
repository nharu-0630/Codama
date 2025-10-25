import math
import random

from config.settings import settings


def add_random_offset(
    lat: float,
    lon: float,
) -> tuple[float, float]:
    """プライバシー保護のため緯度経度にランダムなオフセットを追加"""
    # 緯度方向のオフセット量を度数法で計算（1度≒111km）
    lat_offset_deg = settings.GEO_DELTA_METERS / 111000.0

    # 経度方向のオフセット量を度数法で計算（緯度により補正）
    lon_offset_deg = settings.GEO_DELTA_METERS / (
        111000.0 * math.cos(math.radians(lat))
    )

    # ランダムな角度を生成
    angle = random.uniform(0, 2 * math.pi)

    # ランダムな距離を生成（円形の均一分布）
    distance = random.uniform(0, 1) ** 0.5

    # 緯度と経度のオフセットを計算
    lat_delta = distance * lat_offset_deg * math.sin(angle)
    lon_delta = distance * lon_offset_deg * math.cos(angle)

    return (lat + lat_delta, lon + lon_delta)
