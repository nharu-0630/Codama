from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/")
async def health():
    """ヘルスチェック"""
    return {"status": "ok"}
