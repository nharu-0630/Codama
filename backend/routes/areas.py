from fastapi import APIRouter
from repositories.area_repository import get_all_areas
from schemas.api import APIArea

router = APIRouter(prefix="/areas", tags=["areas"])


@router.get("", response_model=list[APIArea])
async def get_areas():
    """全エリアの一覧を取得"""
    # データベースから全エリアを取得
    db_areas = get_all_areas()
    # APIモデルに変換して返却
    return [APIArea(id=area.id, name=area.name) for area in db_areas]
