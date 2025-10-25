"""Geohash utility functions."""

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
    """Encode latitude and longitude to geohash."""
    return gh.encode(lat, lon, precision=settings.GEO_HASH_PRECISION)


def decode_geo_hash(geo_hash: str) -> tuple[float, float]:
    """Decode geohash to latitude and longitude."""
    pos = gh.decode(geo_hash)
    return pos.latitude, pos.longitude


def get_or_create_cell(lat: float, lon: float) -> dict[str, Any]:
    """Get or create a cell for the given coordinates."""

    geo_hash = encode_geo_hash(lat, lon)
    center_pos = gh.decode(geo_hash)

    # Try to find existing cell
    db_cell = get_cell_by_geo_hash(geo_hash)

    if not db_cell:
        # Get area name from Google Maps
        area_name = _get_area_name_from_geocode(lat, lon)
        if not area_name:
            raise HTTPException(status_code=404, detail="Area not found from geocode")

        # Find area by name
        db_areas = get_all_areas()
        db_area = next((area for area in db_areas if area.name == area_name), None)
        if not db_area:
            raise HTTPException(status_code=404, detail="Area not found")

        # Create new cell
        location_wkt = f"POINT({center_pos.longitude} {center_pos.latitude})"
        db_cell = create_cell(
            geo_hash=geo_hash, location_wkt=location_wkt, area_id=db_area.id
        )

    # Return as dict for backward compatibility
    return {
        "id": db_cell.id,
        "geo_hash": db_cell.geo_hash,
        "area_id": db_cell.area_id,
        "created_at": db_cell.created_at,
        "location": db_cell.location,
    }


def decode_wkt_location(location_wkt: str) -> tuple[float, float]:
    """Parse WKT location string to (latitude, longitude) tuple."""
    point = wkb.loads(location_wkt, hex=True)
    return point.xy[1][0], point.xy[0][0]  # type: ignore


def encode_wkt_location(lat: float, lon: float) -> str:
    """Convert (latitude, longitude) to WKT location string."""
    return wkb.dumps(Point(lon, lat), hex=True, srid=4326)  # type: ignore


def _get_area_name_from_geocode(lat: float, lon: float) -> str | None:
    """Get area name from Google Maps geocoding."""
    geo_code = gmaps.reverse_geocode((lat, lon), language="ja")  # type: ignore
    if geo_code and len(geo_code) > 0:  # type: ignore
        for component in geo_code[0].get("address_components", []):  # type: ignore
            if "sublocality_level_1" in component.get("types", []):  # type: ignore
                return str(component.get("short_name"))  # type: ignore
    return None
