"""Prompt repository for data access."""

from typing import Any, cast

from config.database import supabase
from schemas.db import DBPrompt


def get_prompts_by_area_id(area_id: int) -> list[DBPrompt]:
    response = supabase.from_("prompts").select("*").eq("area_id", area_id).execute()
    data = cast(list[dict[str, Any]], response.data)
    return [DBPrompt(**item) for item in data]


def create_prompt(prompt: str, area_id: int) -> DBPrompt:
    prompt_data: dict[str, Any] = {"prompt": prompt, "area_id": area_id}
    response = supabase.from_("prompts").insert(prompt_data).execute()
    data = cast(list[dict[str, Any]], response.data)
    return DBPrompt(**data[0])
