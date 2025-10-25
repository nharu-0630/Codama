"""Coordinate utilities with randomization for privacy."""

import random


def add_random_offset(
    lat: float,
    lon: float,
    max_offset_meters: float = 100.0,
) -> tuple[float, float]:
    """
    Add random offset to coordinates for privacy.

    Args:
        lat: Original latitude
        lon: Original longitude
        max_offset_meters: Maximum offset in meters (default: 100m)

    Returns:
        Tuple of (latitude, longitude) with random offset applied

    Note:
        - 1 degree of latitude ≈ 111km
        - 1 degree of longitude ≈ 111km * cos(latitude)
        - This function adds a random offset within a circle of max_offset_meters radius
    """
    # Convert meters to degrees (approximate)
    lat_offset_deg = max_offset_meters / 111000.0

    # Longitude offset depends on latitude (closer to poles = larger degree change)
    import math

    lon_offset_deg = max_offset_meters / (111000.0 * math.cos(math.radians(lat)))

    # Generate random angle and distance
    angle = random.uniform(0, 2 * math.pi)
    distance = random.uniform(0, 1) ** 0.5  # Square root for uniform distribution in circle

    # Calculate offsets
    lat_delta = distance * lat_offset_deg * math.sin(angle)
    lon_delta = distance * lon_offset_deg * math.cos(angle)

    return (lat + lat_delta, lon + lon_delta)
