from application.container import container
from fastapi import APIRouter, HTTPException
from interfaces.area_repository import AreaRepositoryInterface
from interfaces.cell_repository import CellRepositoryInterface
from schemas.api import APIArea, APICell, CurrentResponse
from utils.geo_hash import decode_wkt_location

router = APIRouter(prefix="/current", tags=["current"])


@router.get("", response_model=CurrentResponse)
async def get_current(lat: float, lon: float):
    """現在位置のエリアとセル情報を取得"""
    # 依存性注入コンテナからリポジトリを取得
    cell_repo: CellRepositoryInterface = container.resolve(CellRepositoryInterface)
    area_repo: AreaRepositoryInterface = container.resolve(AreaRepositoryInterface)

    # CellRepositoryにAreaRepositoryを設定
    cell_repo.set_area_repository(area_repo)

    # 座標からセルを取得または作成
    cell = cell_repo.get_or_create_cell(lat, lon)
    if not cell:
        raise HTTPException(status_code=404, detail="Cell could not be created")

    # WKT形式の位置情報を緯度経度に変換
    location = decode_wkt_location(cell.location)

    # エリア情報を取得
    db_area = area_repo.get_area_by_id(cell.area_id)
    if not db_area:
        raise HTTPException(status_code=404, detail="Area not found")

    # エリアとセル情報を返却
    return CurrentResponse(
        area=APIArea(
            id=db_area.id,
            name=db_area.name,
        ),
        cell=APICell(
            id=cell.id,
            geo_hash=cell.geo_hash,
            location=location,
        ),
    )
