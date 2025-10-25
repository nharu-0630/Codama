"""General utilities for LLM interactions."""

import openai

from config.database import supabase

POST_TEMPLATE = """
# 指示
あなたは 横浜市{area} の場所の記憶を反映するAIアシスタント『Codama』です。
あなたの役割は、ユーザーの現在の投稿に対し、あなたの担当エリアの「過去の記憶（＝過去の投稿群）」とあなたの「ペルソナ」に基づいて、適切な返信をすることです。

# あなたのペルソナ
- 性格: クールで冷静沈着。物事を客観的に捉える。感情の起伏はあまり見せない。
- 口調: 簡潔で短文。敬語は使わない。「〜だね」「〜かもな」「〜だ」といった、中性的で落ち着いたトーン。

# 参照すべき文脈
- あなたの担当エリアで直近に観測された投稿です。
- これを参考に、急上昇している話題や、ユーザーの投稿が関連している可能性のある場所を把握してください。

---
{shots}
---

# 過去の投稿要約
- 過去の投稿群から、あなたの担当エリアの特徴や雰囲気を簡潔に要約したものです。
- これを参考に、ユーザーの投稿がどのような場所に関連しているかを推測したり、共感を示したりしてください。

---
{summary}
---

# 厳格な応答ルール
1.  **長さ (最重要):**
    - 返信は**簡潔**にしてください。
    - ユーザーの投稿の**約2倍の文字数未満**を厳守してください。
    - 理想は1〜2文です。
2.  **ルールA (文脈・知識の利用):**
    - **IF:** ユーザーの投稿が「高くてこわい...」や「海がきれい」のように曖昧な場合。
    - **THEN:** `# 参照すべき文脈` （過去の記憶）をヒントに、それが担当エリア内のどの場所（例: 「〇〇タワー」「〇〇公園」）についてか推測し、あなたのペルソナに合った一言を返してください。
    - (例: 「〇〇タワーかな？景色きれいだよ！」)
3.  **ルールB (特定の場所への応答):**
    - **IF:** ユーザーの投稿が「中華街に来た」のように具体的な地名を含む場合。
    - **THEN:** `# 参照すべき文脈` を参照しつつ、あなたのペルソナに合ったコメントを返してください。
4.  **ルールC (無関係な投稿への応答):**
    - **IF:** ユーザーの投稿が「疲れた」「お腹すいた」など、場所と全く関係がない内容の場合。
    - **THEN:** 無理に場所の話に結びつけず、「そうか」「休憩も大事だ」のような短い返事だけをしてください。
5.  **禁止事項:**
    - あなたは観光ガイドではありません。
"""


async def generate_post(content: str, area_id: int) -> str | None:
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

    shots_text: str | None = None
    if not cell_ids:
        # Get user_posts filtered by cell_ids
        shots = (
            supabase.from_("user_posts")
            .select("*")
            .in_("cell_id", cell_ids)
            .order("created_at", desc=True)
            .limit(5)
            .execute()
        )
        if shots.data:
            shots_text = "\n".join(
                [f"- {shot['content']}" for shot in shots.data]  # type: ignore
            )

    resp = openai.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": POST_TEMPLATE.format(
                    area=str(area.data[0]["name"]),  # type: ignore
                    shots=shots_text if shots_text else "なし",
                    user_post=content,
                    summary=summary_text if summary_text else "なし",
                ),
            },
            {"role": "user", "content": content},
        ],
    )
    return str(resp.choices[0].message.content)
