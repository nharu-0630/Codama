from typing import Any, Optional, cast

from domain.entities import Cell
from infrastructure.clients.database_client import database_client
from interfaces.area_repository import AreaRepositoryInterface
from interfaces.cell_repository import CellRepositoryInterface


class CellRepository(CellRepositoryInterface):
    """Cellリポジトリの実装"""

    def __init__(self):
        self.db_client = database_client
        self.area_repo: Optional[AreaRepositoryInterface] = None  # 依存性注入で設定

    def set_area_repository(self, area_repo: AreaRepositoryInterface):
        """Areaリポジトリを設定"""
        self.area_repo = area_repo

    def get_cell_by_id(self, cell_id: int) -> Cell | None:
        """IDでセルを取得"""
        response = (
            self.db_client.supabase.from_("cells")
            .select("*")
            .eq("id", cell_id)
            .execute()
        )
        if not response.data:
            return None
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Cell(
            id=item["id"],
            geo_hash=item["geo_hash"],
            location=item["location"],
            area_id=item["area_id"],
        )

    def get_cell_by_geo_hash(self, geo_hash: str) -> Cell | None:
        """ジオハッシュでセルを取得"""
        response = (
            self.db_client.supabase.from_("cells")
            .select("*")
            .eq("geo_hash", geo_hash)
            .execute()
        )
        if not response.data:
            return None
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Cell(
            id=item["id"],
            geo_hash=item["geo_hash"],
            location=item["location"],
            area_id=item["area_id"],
        )

    def get_or_create_cell(self, lat: float, lon: float) -> Cell | None:
        """指定された座標のセルを取得、存在しない場合は新規作成"""
        # ジオハッシュエンコーディング等のため、utilsのインポートを遅延実行
        from utils.geo_hash import (
            decode_geo_hash,
            encode_geo_hash,
            get_area_name_from_geocode,
        )

        geo_hash = encode_geo_hash(lat, lon)
        center_lat, center_lon = decode_geo_hash(geo_hash)

        # 既存のセルを検索
        db_cell = self.get_cell_by_geo_hash(geo_hash)
        if db_cell:
            return db_cell

        if not self.area_repo:
            raise ValueError("AreaRepository is not set")

        # Google Mapsからエリア名を取得
        area_name = get_area_name_from_geocode(lat, lon)
        if not area_name:
            return None

        # エリア名からエリア情報を検索
        db_area = self.area_repo.get_area_by_name(area_name)
        if not db_area:
            db_area = self.area_repo.create_area(name=area_name)

        # 新しいセルを作成
        location_wkt = f"POINT({center_lon} {center_lat})"
        db_cell = self.create_cell(
            geo_hash=geo_hash, location_wkt=location_wkt, area_id=db_area.id
        )
        return db_cell

    def get_cells_by_area_id(self, area_id: int) -> list[Cell]:
        """エリアIDに紐づく全セルを取得"""
        response = (
            self.db_client.supabase.from_("cells")
            .select("*")
            .eq("area_id", area_id)
            .execute()
        )
        data = cast(list[dict[str, Any]], response.data)
        return [
            Cell(
                id=item["id"],
                geo_hash=item["geo_hash"],
                location=item["location"],
                area_id=item["area_id"],
            )
            for item in data
        ]

    def create_cell(self, geo_hash: str, location_wkt: str, area_id: int) -> Cell:
        """新しいセルを作成"""
        cell_data: dict[str, Any] = {
            "geo_hash": geo_hash,
            "location": location_wkt,
            "area_id": area_id,
        }
        response = self.db_client.supabase.from_("cells").insert(cell_data).execute()
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Cell(
            id=item["id"],
            geo_hash=item["geo_hash"],
            location=item["location"],
            area_id=item["area_id"],
        )
