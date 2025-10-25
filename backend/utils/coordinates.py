"""Coordinate utilities with randomization for privacy."""

import math
import random

from config.settings import settings


def add_random_offset(
    lat: float,
    lon: float,
) -> tuple[float, float]:
    """Add a random offset to the given latitude and longitude for privacy."""
    lat_offset_deg = settings.GEO_DELTA_METERS / 111000.0
    lon_offset_deg = settings.GEO_DELTA_METERS / (
        111000.0 * math.cos(math.radians(lat))
    )
    angle = random.uniform(0, 2 * math.pi)
    distance = random.uniform(0, 1) ** 0.5

    lat_delta = distance * lat_offset_deg * math.sin(angle)
    lon_delta = distance * lon_offset_deg * math.cos(angle)

    return (lat + lat_delta, lon + lon_delta)
