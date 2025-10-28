from abc import ABC, abstractmethod
from datetime import datetime
from typing import TYPE_CHECKING, List
from uuid import UUID

if TYPE_CHECKING:
    from domain.entities import LLMPost, UserPost


class PostRepositoryInterface(ABC):
    """投稿リポジトリの抽象化インタフェース"""

    @abstractmethod
    def get_user_post_by_uuid(self, post_uuid: str) -> "UserPost | None":
        """UUIDでユーザー投稿を取得"""
        pass

    @abstractmethod
    def get_user_posts_by_location(
        self, geo_hash: str, length: int
    ) -> List["UserPost"]:
        """位置でユーザー投稿を取得"""
        pass

    @abstractmethod
    def get_user_posts_by_user_uuid(self, user_uuid: str) -> List["UserPost"]:
        """ユーザーUUIDで投稿を取得"""
        pass

    @abstractmethod
    def get_user_posts_by_uuids(self, post_uuids: List[str]) -> List["UserPost"]:
        """UUIDリストで投稿を取得"""
        pass

    @abstractmethod
    def create_user_post(
        self, content: str, user_uuid: UUID, cell_id: int, location_wkt: str
    ) -> "UserPost":
        """新しいユーザー投稿を作成"""
        pass

    @abstractmethod
    def get_user_posts_by_cell_ids_after_date(
        self, cell_ids: List[int], target_date: datetime
    ) -> List["UserPost"]:
        """セルIDリストと日付以降で投稿を取得"""
        pass

    @abstractmethod
    def get_recent_user_posts_by_cell_ids(
        self, cell_ids: List[int], limit: int = 100
    ) -> List["UserPost"]:
        """セルIDリストで最近の投稿を取得"""
        pass

    @abstractmethod
    def create_llm_post(
        self, content: str, user_post_uuid: UUID, location_wkt: str
    ) -> "LLMPost":
        """新しいLLM返信を作成"""
        pass

    @abstractmethod
    def get_user_posts_with_replies(self, cell_ids: List[int]) -> List["UserPost"]:
        """返信を含む投稿を取得"""
        pass

    @abstractmethod
    def get_replies_for_posts(self, post_uuids: List[str]) -> List["LLMPost"]:
        """投稿UUIDリストに対する返信を取得"""
        pass
