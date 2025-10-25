"""General utilities for LLM interactions."""

import openai

from config.database import supabase

SUMMARY_TEMPLATE = """
# 指示
あなたは 横浜市{area} の場所の記憶を反映するAIアシスタント『Codama』です。
あなたの役割は、過去の投稿要約と新たなユーザーの投稿をもとに、新たな投稿要約を生成することです。
要約本文のみを出力してください。

# 過去の投稿要約
- 過去の投稿群から、あなたの担当エリアの特徴や雰囲気を簡潔に要約したものです。

---
{summary}
---

# ユーザーの投稿

---
{shots}
---
"""


async def generate_summary(area_id: int) -> str | None:
    """Generate a response from the LLM based on the given content and area."""
    # Get area information
    area = supabase.from_("areas").select("*").eq("id", area_id).execute()
    if not area.data:
        return None

    # Get the latest prompt summary for the given area_id
    summary = (
        supabase.from_("prompts")
        .select("*")
        .eq("area_id", area_id)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )
    summary_text: str | None = None
    if summary.data:
        summary_text = str(summary.data[0]["prompt"])  # type: ignore

    # Get cell_ids for the given area_id
    cells = supabase.from_("cells").select("id").eq("area_id", area_id).execute()
    cell_ids = [int(cell["id"]) for cell in cells.data] if cells.data else []  # type: ignore
    if not cell_ids:
        return None

    # Get user_posts filtered by cell_ids
    created_at = (
        str(summary.data[0]["created_at"]) if summary.data else "1970-01-01T00:00:00Z"  # type: ignore
    )
    shots = (
        supabase.from_("user_posts")
        .select("*")
        .in_("cell_id", cell_ids)
        .filter("created_at", "gt", created_at)  # type: ignore
        .execute()
    )
    if not shots.data:
        return
    shots_text = "\n".join(
        [f"- {shot['content']}" for shot in shots.data]  # type: ignore
    )

    resp = openai.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": SUMMARY_TEMPLATE.format(
                    area=str(area.data[0]["name"]),  # type: ignore
                    summary=summary_text if summary_text else "なし",
                    shots=shots_text,
                ),
            },
        ],
    )
    return str(resp.choices[0].message.content)
