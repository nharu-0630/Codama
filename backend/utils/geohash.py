"""Geohash utility functions."""

from typing import Any

import pygeohash as gh  # type: ignore
from fastapi import HTTPException
from shapely import wkb
from shapely.geometry import Point

from config.database import gmaps, supabase
from config.settings import settings


def encode_location(lat: float, lon: float) -> str:
    """Encode latitude and longitude to geohash."""
    return gh.encode(lat, lon, precision=settings.GEO_HASH_PRECISION)


def decode_geohash(geo_hash: str) -> tuple[float, float]:
    """Decode geohash to latitude and longitude."""
    pos = gh.decode(geo_hash)
    return pos.latitude, pos.longitude


def get_or_create_cell(lat: float, lon: float) -> dict[str, Any]:
    """Get or create a cell for the given coordinates."""
    geo_hash = encode_location(lat, lon)
    center_pos = gh.decode(geo_hash)

    cell = (
        supabase.from_("cells")
        .select("id, geo_hash, area_id, created_at, location")
        .like("geo_hash", f"{geo_hash}%")
        .execute()
    )

    if not cell.data:
        # Get area name from Google Maps
        area_name = _get_area_name_from_geocode(lat, lon)
        if not area_name:
            raise HTTPException(status_code=404, detail="Area not found from geocode")

        # Get or create area
        area = supabase.from_("areas").select("*").eq("name", area_name).execute()
        if not area.data:
            raise HTTPException(status_code=404, detail="Area not found")

        # Create new cell
        new_cell: dict[str, Any] = {
            "geo_hash": geo_hash,
            "location": f"POINT({center_pos.longitude} {center_pos.latitude})",
            "area_id": int(area.data[0]["id"]),  # type: ignore
        }
        supabase.from_("cells").insert(new_cell).execute()

        # Fetch the created cell
        cell = (
            supabase.from_("cells")
            .select("id, geo_hash, area_id, created_at, location")
            .like("geo_hash", f"{geo_hash}%")
            .execute()
        )
        if not cell.data:
            raise HTTPException(status_code=404, detail="Cell not found")

    return cell.data[0]  # type: ignore


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
