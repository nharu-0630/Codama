"""Cell repository for data access."""

from typing import Any, cast

from config.database import supabase
from schemas.db import DBCell


def get_cell_by_id(cell_id: int) -> DBCell | None:
    response = supabase.from_("cells").select("*").eq("id", cell_id).execute()
    if not response.data:
        return None
    data = cast(list[dict[str, Any]], response.data)
    return DBCell(**data[0])


def get_cell_by_geo_hash(geo_hash: str) -> DBCell | None:
    response = supabase.from_("cells").select("*").eq("geo_hash", geo_hash).execute()
    if not response.data:
        return None
    data = cast(list[dict[str, Any]], response.data)
    return DBCell(**data[0])


def get_cells_by_area_id(area_id: int) -> list[DBCell]:
    """Get all cells for a given area.

    Args:
        area_id: Area ID

    Returns:
        List of DBCell
    """
    response = supabase.from_("cells").select("*").eq("area_id", area_id).execute()
    data = cast(list[dict[str, Any]], response.data)
    return [DBCell(**item) for item in data]


def create_cell(geo_hash: str, location_wkt: str, area_id: int) -> DBCell:
    cell_data: dict[str, Any] = {
        "geo_hash": geo_hash,
        "location": location_wkt,
        "area_id": area_id,
    }
    response = supabase.from_("cells").insert(cell_data).execute()
    data = cast(list[dict[str, Any]], response.data)
    return DBCell(**data[0])
