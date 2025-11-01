from fastapi import APIRouter

from application.container import container
from interfaces.area_repository import AreaRepositoryInterface
from schemas.api import APIArea

router = APIRouter(prefix="/areas", tags=["areas"])


@router.get("", response_model=list[APIArea])
async def get_areas():
    """全エリアの一覧を取得"""
    # 依存性注入コンテナからリポジトリを取得
    area_repo: AreaRepositoryInterface = container.resolve(AreaRepositoryInterface)

    # データベースから全エリアを取得
    db_areas = area_repo.get_all_areas()

    # APIモデルに変換して返却
    return [APIArea(id=area.id, name=area.name) for area in db_areas]
