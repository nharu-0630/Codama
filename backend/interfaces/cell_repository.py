from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from domain.entities import Cell


class CellRepositoryInterface(ABC):
    """Cellリポジトリの抽象化インタフェース"""

    @abstractmethod
    def get_cell_by_id(self, cell_id: int) -> "Cell | None":
        """IDでセルを取得"""
        pass

    @abstractmethod
    def get_cell_by_geo_hash(self, geo_hash: str) -> "Cell | None":
        """ジオハッシュでセルを取得"""
        pass

    @abstractmethod
    def get_or_create_cell(self, lat: float, lon: float) -> "Cell | None":
        """指定された座標のセルを取得、存在しない場合は新規作成"""
        pass

    @abstractmethod
    def get_cells_by_area_id(self, area_id: int) -> list["Cell"]:
        """エリアIDに紐づく全セルを取得"""
        pass

    @abstractmethod
    def create_cell(self, geo_hash: str, location_wkt: str, area_id: int) -> "Cell":
        """新しいセルを作成"""
        pass
