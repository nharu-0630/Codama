"""Current location routes."""

from fastapi import APIRouter, Depends, HTTPException
from repositories.area_repository import get_area_by_id
from schemas.api import APIArea, APICell, CurrentResponse
from utils.auth import get_current_user
from backend.utils.geo_hash import decode_wkt_location, get_or_create_cell

router = APIRouter(prefix="/current", tags=["current"])


@router.get(
    "", response_model=CurrentResponse, dependencies=[Depends(get_current_user)]
)
async def get_current(lat: float, lon: float):
    cell_data = get_or_create_cell(lat, lon)

    location_wkt = str(cell_data["location"])
    location = decode_wkt_location(location_wkt)

    area_id = int(cell_data["area_id"])  # type: ignore
    db_area = get_area_by_id(area_id)
    if not db_area:
        raise HTTPException(status_code=404, detail="Area not found")

    return CurrentResponse(
        area=APIArea(
            id=db_area.id,
            name=db_area.name,
        ),
        cell=APICell(
            id=cell_data["id"],  # type: ignore
            geo_hash=cell_data["geo_hash"],  # type: ignore
            location=location,
        ),
    )
