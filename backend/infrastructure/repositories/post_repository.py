from typing import Any, List, cast
from uuid import UUID

import geohash

from domain.entities import Area, Cell, LLMPost, UserPost
from infrastructure.clients.database_client import database_client
from interfaces.post_repository import PostRepositoryInterface


class PostRepository(PostRepositoryInterface):
    """投稿リポジトリの実装"""

    def __init__(self):
        self.db_client = database_client

    def get_user_post_by_uuid(self, post_uuid: str) -> UserPost | None:
        """UUIDでユーザー投稿を取得"""
        post_response = (
            self.db_client.supabase.from_("user_posts")
            .select(
                "*, cells!inner(id, geo_hash, location, area_id, created_at, areas(id, name, created_at))"
            )
            .eq("uuid", post_uuid)
            .single()
            .execute()
        )
        if not post_response.data:
            return None
        data = cast(dict[str, Any], post_response.data)
        cell_data = data["cells"]
        area_data = cell_data["areas"]

        # Areaエンティティを作成
        area = Area(id=area_data["id"], name=area_data["name"])

        # Cellエンティティを作成
        cell = Cell(
            id=cell_data["id"],
            geo_hash=cell_data["geo_hash"],
            location=cell_data["location"],
            area_id=cell_data["area_id"],
            area=area,
        )

        return UserPost(
            id=data["id"],
            uuid=data["uuid"],
            content=data["content"],
            user_uuid=data["user_uuid"],
            cell_id=data["cell_id"],
            location=data["location"],
            created_at=data["created_at"],
            cell=cell,
        )

    def get_user_posts_by_location(self, geo_hash: str, length: int) -> List[UserPost]:
        """位置でユーザー投稿を取得"""
        neighbor_hashes = geohash.neighbors(geo_hash)
        geo_hashes: list[str] = [geo_hash] + neighbor_hashes

        query = (
            self.db_client.supabase.from_("user_posts")
            .select(
                "*, cells!inner(id, geo_hash, location, area_id, created_at, areas(id, name, created_at))"
            )
            .in_("cells.geo_hash", geo_hashes)
            .order("created_at", desc=True)
            .limit(length)
        )

        posts = query.execute()
        data = cast(list[dict[str, Any]], posts.data)
        return [self._create_user_post_with_cell(item) for item in data]

    def _create_user_post_with_cell(self, data: dict[str, Any]) -> UserPost:
        """データからUserPostとCellを適切に設定して作成"""
        cell_data = data["cells"]
        area_data = cell_data["areas"]

        # Areaエンティティを作成
        area = Area(id=area_data["id"], name=area_data["name"])

        # Cellエンティティを作成
        cell = Cell(
            id=cell_data["id"],
            geo_hash=cell_data["geo_hash"],
            location=cell_data["location"],
            area_id=cell_data["area_id"],
            area=area,
        )

        return UserPost(
            id=data["id"],
            uuid=data["uuid"],
            content=data["content"],
            user_uuid=data["user_uuid"],
            cell_id=data["cell_id"],
            location=data["location"],
            created_at=data["created_at"],
            cell=cell,
        )

    def get_user_posts_by_user_uuid(self, user_uuid: str) -> List[UserPost]:
        """ユーザーUUIDで投稿を取得"""
        posts = (
            self.db_client.supabase.from_("user_posts")
            .select(
                "*, cells!inner(id, geo_hash, location, area_id, created_at, areas(id, name, created_at))"
            )
            .eq("user_uuid", user_uuid)
            .execute()
        )
        data = cast(list[dict[str, Any]], posts.data)
        return [self._create_user_post_with_cell(item) for item in data]

    def get_user_posts_by_uuids(self, post_uuids: List[str]) -> List[UserPost]:
        """UUIDリストで投稿を取得"""
        if not post_uuids:
            return []
        posts = (
            self.db_client.supabase.from_("user_posts")
            .select(
                "*, cells!inner(id, geo_hash, location, area_id, created_at, areas(id, name, created_at))"
            )
            .in_("uuid", post_uuids)
            .execute()
        )
        data = cast(list[dict[str, Any]], posts.data)
        return [self._create_user_post_with_cell(item) for item in data]

    def create_user_post(
        self, content: str, user_uuid: UUID, cell_id: int, location_wkt: str
    ) -> UserPost:
        """新しいユーザー投稿を作成"""
        post_data: dict[str, Any] = {
            "content": content,
            "cell_id": cell_id,
            "user_uuid": str(user_uuid),
            "location": location_wkt,
        }
        response = (
            self.db_client.supabase.from_("user_posts").insert(post_data).execute()
        )
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return UserPost(
            id=item["id"],
            uuid=item["uuid"],
            content=item["content"],
            user_uuid=item["user_uuid"],
            cell_id=item["cell_id"],
            location=item["location"],
            created_at=item["created_at"],
        )

    def get_user_posts_by_cell_ids_after_date(
        self,
        cell_ids: List[int],
        target_date: Any,  # datetime object
    ) -> List[UserPost]:
        """セルIDリストと日付以降で投稿を取得"""
        if not cell_ids:
            return []

        posts = (
            self.db_client.supabase.from_("user_posts")
            .select(
                "*, cells!inner(id, geo_hash, location, area_id, created_at, areas(id, name, created_at))"
            )
            .in_("cell_id", cell_ids)
            .filter("created_at", "gt", target_date)
            .execute()
        )

        data = cast(list[dict[str, Any]], posts.data)
        return [self._create_user_post_with_cell(item) for item in data]

    def get_recent_user_posts_by_cell_ids(
        self, cell_ids: List[int], limit: int = 100
    ) -> List[UserPost]:
        """セルIDリストで最近の投稿を取得"""
        if not cell_ids:
            return []

        posts = (
            self.db_client.supabase.from_("user_posts")
            .select(
                "*, cells!inner(id, geo_hash, location, area_id, created_at, areas(id, name, created_at))"
            )
            .in_("cell_id", cell_ids)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )

        data = cast(list[dict[str, Any]], posts.data)
        return [self._create_user_post_with_cell(item) for item in data]

    def create_llm_post(
        self, content: str, user_post_uuid: UUID, location_wkt: str
    ) -> LLMPost:
        """新しいLLM返信を作成"""
        post_data: dict[str, Any] = {
            "content": content,
            "user_post_uuid": str(user_post_uuid),
            "location": location_wkt,
        }
        response = (
            self.db_client.supabase.from_("llm_posts").insert(post_data).execute()
        )
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return LLMPost(
            id=item["id"],
            uuid=item["uuid"],
            content=item["content"],
            user_post_uuid=item["user_post_uuid"],
            location=item["location"],
            created_at=item["created_at"],
        )

    def get_user_posts_with_replies(self, cell_ids: List[int]) -> List[UserPost]:
        """返信を含む投稿を取得"""
        # このメソッドはインターフェースの変更が必要
        # 簡略化された実装として、セルIDによる投稿取得のみを実行
        return self.get_recent_user_posts_by_cell_ids(cell_ids, 100)

    def get_replies_for_posts(self, post_uuids: List[str]) -> List[LLMPost]:
        """投稿UUIDリストに対する返信を取得"""
        if not post_uuids:
            return []

        replies = (
            self.db_client.supabase.from_("llm_posts")
            .select("*")
            .in_("user_post_uuid", post_uuids)
            .execute()
        )
        data = cast(list[dict[str, Any]], replies.data)
        return [
            LLMPost(
                id=item["id"],
                uuid=item["uuid"],
                content=item["content"],
                user_post_uuid=item["user_post_uuid"],
                location=item["location"],
                created_at=item["created_at"],
            )
            for item in data
        ]
