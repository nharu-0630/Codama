from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from domain.entities import Area


class AreaRepositoryInterface(ABC):
    """Areaリポジトリの抽象化インタフェース"""

    @abstractmethod
    def get_all_areas(self) -> list["Area"]:
        """全エリアの一覧を取得"""
        pass

    @abstractmethod
    def get_area_by_id(self, area_id: int) -> "Area | None":
        """IDでエリアを取得"""
        pass

    @abstractmethod
    def get_area_by_name(self, name: str) -> "Area | None":
        """名前でエリアを取得"""
        pass

    @abstractmethod
    def create_area(self, name: str) -> "Area":
        """新しいエリアを作成"""
        pass
