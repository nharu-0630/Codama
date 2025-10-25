"""Prompt routes."""

import asyncio
import threading

from fastapi import APIRouter

from config.database import supabase
from schemas.model import UpdatePromptResponse
from utils.summary_llm import generate_summary

router = APIRouter(tags=["batch"])


@router.post("/batch/prompts/update", response_model=UpdatePromptResponse)
async def update_prompt():
    """Batch update prompts."""

    async def batch_update():
        areas = supabase.from_("areas").select("*").execute()
        area_ids = [int(area["id"]) for area in areas.data]  # type: ignore
        for area_id in area_ids:
            summary = await generate_summary(area_id)
            if summary:
                supabase.from_("prompts").insert(
                    {"prompt": summary, "area_id": area_id}
                ).execute()

    threading.Thread(target=lambda: asyncio.run(batch_update())).start()
    return UpdatePromptResponse(success=True)
