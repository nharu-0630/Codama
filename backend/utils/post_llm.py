import openai

from application.container import container
from interfaces.area_repository import AreaRepositoryInterface
from interfaces.cell_repository import CellRepositoryInterface
from interfaces.post_repository import PostRepositoryInterface
from interfaces.prompt_repository import PromptRepositoryInterface

POST_TEMPLATE = """
# 指示
あなたは {area} の場所の記憶を反映するAIアシスタント『Codama』です。
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
    """ユーザーの投稿内容とエリア情報に基づいてLLMから返信を生成"""
    # 依存性注入コンテナからリポジトリを取得
    area_repo: AreaRepositoryInterface = container.resolve(AreaRepositoryInterface)
    cell_repo: CellRepositoryInterface = container.resolve(CellRepositoryInterface)
    post_repo: PostRepositoryInterface = container.resolve(PostRepositoryInterface)
    prompt_repo: PromptRepositoryInterface = container.resolve(
        PromptRepositoryInterface
    )

    # エリア情報を取得
    db_area = area_repo.get_area_by_id(area_id)
    if not db_area:
        return None

    # 指定されたエリアの最新のプロンプト要約を取得
    db_prompts = prompt_repo.get_prompts_by_area_id(area_id)
    summary_text: str | None = None

    if db_prompts:
        # 作成日時の降順でソートして最新のプロンプトを取得
        sorted_prompts = sorted(db_prompts, key=lambda p: p.created_at, reverse=True)
        summary_text = sorted_prompts[0].prompt

    # エリアIDに紐づくセルIDのリストを取得
    db_cells = cell_repo.get_cells_by_area_id(area_id)
    cell_ids = [cell.id for cell in db_cells]

    # 参照用の最近の投稿を取得
    shots_text: str | None = None
    if cell_ids:
        # セルIDでフィルタして最近の投稿を5件取得
        db_posts = post_repo.get_recent_user_posts_by_cell_ids(cell_ids, limit=5)
        if db_posts:
            shots_text = "\n".join([f"- {post.content}" for post in db_posts])

    # LLMを使用して返信を生成
    resp = openai.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": POST_TEMPLATE.format(
                    area=db_area.name,
                    shots=shots_text if shots_text else "なし",
                    user_post=content,
                    summary=summary_text if summary_text else "なし",
                ),
            },
            {"role": "user", "content": content},
        ],
    )
    return str(resp.choices[0].message.content)
