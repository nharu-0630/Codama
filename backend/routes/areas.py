"""Area routes."""

from fastapi import APIRouter
from repositories.area_repository import get_all_areas
from schemas.api import APIArea

router = APIRouter(prefix="/areas", tags=["areas"])


@router.get("", response_model=list[APIArea])
async def get_areas():
    db_areas = get_all_areas()
    return [APIArea(id=area.id, name=area.name) for area in db_areas]
