from fastapi import APIRouter, Depends, HTTPException

from repositories.area_repository import get_area_by_id
from repositories.cell_repository import get_or_create_cell
from schemas.api import APIArea, APICell, CurrentResponse
from utils.auth import get_current_user
from utils.geo_hash import decode_wkt_location

router = APIRouter(prefix="/current", tags=["current"])


@router.get(
    "", response_model=CurrentResponse, dependencies=[Depends(get_current_user)]
)
async def get_current(lat: float, lon: float):
    """現在位置のエリアとセル情報を取得"""
    # 座標からセルを取得または作成
    cell = get_or_create_cell(lat, lon)
    if not cell:
        raise HTTPException(status_code=404, detail="Cell could not be created")

    # WKT形式の位置情報を緯度経度に変換
    location = decode_wkt_location(cell.location)

    # エリア情報を取得
    db_area = get_area_by_id(cell.area_id)
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
