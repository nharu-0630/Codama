"""General utilities for LLM interactions."""

import openai

from repositories.area_repository import get_area_by_id
from repositories.cell_repository import get_cells_by_area_id
from repositories.post_repository import get_user_posts_by_cell_ids_after_date
from repositories.prompt_repository import get_prompts_by_area_id

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
    db_area = get_area_by_id(area_id)
    if not db_area:
        return None

    # Get the latest prompt summary for the given area_id
    db_prompts = get_prompts_by_area_id(area_id)
    summary_text: str | None = None
    latest_created_at = "1970-01-01T00:00:00Z"

    if db_prompts:
        # Sort by created_at descending
        sorted_prompts = sorted(db_prompts, key=lambda p: p.created_at, reverse=True)
        summary_text = sorted_prompts[0].prompt
        latest_created_at = str(sorted_prompts[0].created_at)

    # Get cell_ids for the given area_id
    db_cells = get_cells_by_area_id(area_id)
    cell_ids = [cell.id for cell in db_cells]
    if not cell_ids:
        return None

    # Get user_posts filtered by cell_ids and created after latest_created_at
    db_posts = get_user_posts_by_cell_ids_after_date(cell_ids, latest_created_at)
    if not db_posts:
        return None

    shots_text = "\n".join([f"- {post.content}" for post in db_posts])

    resp = openai.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": SUMMARY_TEMPLATE.format(
                    area=db_area.name,
                    summary=summary_text if summary_text else "なし",
                    shots=shots_text,
                ),
            },
        ],
    )
    return str(resp.choices[0].message.content)
