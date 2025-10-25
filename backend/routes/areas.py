"""Area routes."""

from fastapi import APIRouter

from config.database import supabase
from schemas.model import Area

router = APIRouter(prefix="/areas", tags=["areas"])


@router.get("", response_model=list[Area])
async def get_areas():
    """Get all available areas."""
    areas = supabase.from_("areas").select("*").execute()
    return [
        Area(id=area["id"], name=area["name"], created_at=area["created_at"])  # type: ignore
        for area in areas.data
    ]
