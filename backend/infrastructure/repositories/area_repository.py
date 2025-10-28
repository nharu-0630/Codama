from typing import Any, cast

from domain.entities import Area
from infrastructure.clients.database_client import database_client
from interfaces.area_repository import AreaRepositoryInterface


class AreaRepository(AreaRepositoryInterface):
    """Areaリポジトリの実装"""

    def __init__(self):
        self.db_client = database_client

    def get_all_areas(self) -> list[Area]:
        """全エリアの一覧を取得"""
        response = self.db_client.supabase.from_("areas").select("*").execute()
        data = cast(list[dict[str, Any]], response.data)
        return [Area(id=item["id"], name=item["name"]) for item in data]

    def get_area_by_id(self, area_id: int) -> Area | None:
        """IDでエリアを取得"""
        response = (
            self.db_client.supabase.from_("areas")
            .select("*")
            .eq("id", area_id)
            .execute()
        )
        if not response.data:
            return None
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Area(id=item["id"], name=item["name"])

    def get_area_by_name(self, name: str) -> Area | None:
        """名前でエリアを取得"""
        response = (
            self.db_client.supabase.from_("areas")
            .select("*")
            .eq("name", name)
            .execute()
        )
        if not response.data:
            return None
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Area(id=item["id"], name=item["name"])

    def create_area(self, name: str) -> Area:
        """新しいエリアを作成"""
        area_data: dict[str, Any] = {"name": name}
        response = self.db_client.supabase.from_("areas").insert(area_data).execute()
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Area(id=item["id"], name=item["name"])
