from abc import ABC, abstractmethod
from typing import TYPE_CHECKING, List

if TYPE_CHECKING:
    from domain.entities import Prompt


class PromptRepositoryInterface(ABC):
    """プロンプトリポジトリの抽象化インタフェース"""

    @abstractmethod
    def get_prompts_by_area_id(self, area_id: int) -> List["Prompt"]:
        """エリアIDでプロンプトを取得"""
        pass

    @abstractmethod
    def create_prompt(self, prompt: str, area_id: int) -> "Prompt":
        """新しいプロンプトを作成"""
        pass
