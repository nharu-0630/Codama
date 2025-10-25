from typing import Any, cast

from config.database import supabase
from schemas.db import DBPrompt


def get_prompts_by_area_id(area_id: int) -> list[DBPrompt]:
    """エリアIDに紐づくプロンプト一覧を取得"""
    # エリアIDでプロンプトを検索
    response = supabase.from_("prompts").select("*").eq("area_id", area_id).execute()
    # 取得したデータをDBPromptモデルのリストに変換
    data = cast(list[dict[str, Any]], response.data)
    return [DBPrompt(**item) for item in data]


def create_prompt(prompt: str, area_id: int) -> DBPrompt:
    """新しいプロンプトを作成"""
    # プロンプトデータを構築
    prompt_data: dict[str, Any] = {"prompt": prompt, "area_id": area_id}
    # データベースにプロンプトを挿入
    response = supabase.from_("prompts").insert(prompt_data).execute()
    # 作成されたプロンプトをDBPromptモデルに変換して返却
    data = cast(list[dict[str, Any]], response.data)
    return DBPrompt(**data[0])
