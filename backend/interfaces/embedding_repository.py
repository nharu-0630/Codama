from abc import ABC, abstractmethod
from typing import TYPE_CHECKING, List
from uuid import UUID

if TYPE_CHECKING:
    from domain.entities import EmbeddingUserPost


class EmbeddingRepositoryInterface(ABC):
    """埋め込みリポジトリの抽象化インタフェース"""

    @abstractmethod
    def create_embedding(
        self, user_post_uuid: UUID, embedding: List[float]
    ) -> "EmbeddingUserPost":
        """投稿の埋め込みベクトルを作成"""
        pass

    @abstractmethod
    def find_similar_posts(
        self,
        query_embedding: List[float],
        match_count: int | None = None,
        threshold: float | None = None,
    ) -> List["EmbeddingUserPost"]:
        """埋め込みベクトルから類似投稿を検索"""
        pass
