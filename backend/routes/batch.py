import asyncio
import threading

from application.container import container
from fastapi import APIRouter
from interfaces.area_repository import AreaRepositoryInterface
from interfaces.prompt_repository import PromptRepositoryInterface
from schemas.api import UpdatePromptResponse
from utils.summary_llm import generate_summary

router = APIRouter(tags=["batch"])


@router.post("/batch/prompts/update", response_model=UpdatePromptResponse)
async def update_prompt():
    """全エリアのプロンプトをバッチ更新"""

    async def batch_update():
        # 依存性注入コンテナからリポジトリを取得
        area_repo: AreaRepositoryInterface = container.resolve(AreaRepositoryInterface)
        prompt_repo: PromptRepositoryInterface = container.resolve(
            PromptRepositoryInterface
        )

        # 全エリアを取得
        db_areas = area_repo.get_all_areas()
        area_ids = [area.id for area in db_areas]

        # 各エリアごとに要約を生成してプロンプトを作成
        for area_id in area_ids:
            summary = await generate_summary(area_id)
            if summary:
                prompt_repo.create_prompt(prompt=summary, area_id=area_id)

    # バックグラウンドでバッチ処理を実行
    threading.Thread(target=lambda: asyncio.run(batch_update())).start()
    return UpdatePromptResponse(success=True)
