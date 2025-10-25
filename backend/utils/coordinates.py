"""Coordinate utilities with randomization for privacy."""

import math
import random


def add_random_offset(
    lat: float,
    lon: float,
    max_offset_meters: float = 100.0,
) -> tuple[float, float]:
    """Add a random offset to the given latitude and longitude for privacy."""
    lat_offset_deg = max_offset_meters / 111000.0
    lon_offset_deg = max_offset_meters / (111000.0 * math.cos(math.radians(lat)))
    angle = random.uniform(0, 2 * math.pi)
    distance = random.uniform(0, 1) ** 0.5

    lat_delta = distance * lat_offset_deg * math.sin(angle)
    lon_delta = distance * lon_offset_deg * math.cos(angle)

    return (lat + lat_delta, lon + lon_delta)
