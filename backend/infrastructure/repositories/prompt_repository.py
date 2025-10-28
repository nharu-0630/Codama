from typing import Any, List, cast

from domain.entities import Prompt
from infrastructure.clients.database_client import database_client
from interfaces.prompt_repository import PromptRepositoryInterface


class PromptRepository(PromptRepositoryInterface):
    """Promptリポジトリの実装"""

    def __init__(self):
        self.db_client = database_client

    def get_prompts_by_area_id(self, area_id: int) -> List[Prompt]:
        """エリアIDでプロンプトを取得"""
        response = (
            self.db_client.supabase.from_("prompts")
            .select("*")
            .eq("area_id", area_id)
            .execute()
        )
        data = cast(list[dict[str, Any]], response.data)
        return [
            Prompt(
                id=item["id"],
                prompt=item["prompt"],
                area_id=item["area_id"],
                created_at=item["created_at"],
            )
            for item in data
        ]

    def create_prompt(self, prompt: str, area_id: int) -> Prompt:
        """新しいプロンプトを作成"""
        prompt_data: dict[str, Any] = {"prompt": prompt, "area_id": area_id}
        response = (
            self.db_client.supabase.from_("prompts").insert(prompt_data).execute()
        )
        data = cast(list[dict[str, Any]], response.data)
        item = data[0]
        return Prompt(
            id=item["id"],
            prompt=item["prompt"],
            area_id=item["area_id"],
            created_at=item["created_at"],
        )
