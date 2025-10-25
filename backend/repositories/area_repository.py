"""Area repository for data access."""

from typing import Any, cast

from config.database import supabase
from schemas.db import DBArea


def get_all_areas() -> list[DBArea]:
    response = supabase.from_("areas").select("*").execute()
    data = cast(list[dict[str, Any]], response.data)
    return [DBArea(**item) for item in data]


def get_area_by_id(area_id: int) -> DBArea | None:
    response = supabase.from_("areas").select("*").eq("id", area_id).execute()
    if not response.data:
        return None
    data = cast(list[dict[str, Any]], response.data)
    return DBArea(**data[0])
