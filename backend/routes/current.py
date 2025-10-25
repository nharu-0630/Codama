"""Current location routes."""

from fastapi import APIRouter, Depends, HTTPException

from config.database import supabase
from schemas.model import Area, Cell, CurrentResponse
from utils.auth import get_current_user
from utils.geohash import decode_wkt_location, get_or_create_cell

router = APIRouter(prefix="/current", tags=["current"])


@router.get(
    "", response_model=CurrentResponse, dependencies=[Depends(get_current_user)]
)
async def get_current(lat: float, lon: float):
    """Get current cell and area information for given coordinates."""
    cell_data = get_or_create_cell(lat, lon)

    location_wkt = str(cell_data["location"])
    location = decode_wkt_location(location_wkt)

    area_id = int(cell_data["area_id"])  # type: ignore
    area = supabase.from_("areas").select("*").eq("id", area_id).execute()
    if not area.data:
        raise HTTPException(status_code=404, detail="Area not found")

    return CurrentResponse(
        area=Area(
            id=area.data[0]["id"],  # type: ignore
            name=area.data[0]["name"],  # type: ignore
        ),
        cell=Cell(
            id=cell_data["id"],  # type: ignore
            geo_hash=cell_data["geo_hash"],  # type: ignore
            location=location,
        ),
    )
