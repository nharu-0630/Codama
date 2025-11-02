from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from application.container import container
from routes import areas, auth, batch, current, health, posts


def create_app() -> FastAPI:
    """FastAPIアプリケーションの作成と設定"""
    # FastAPIインスタンスを作成
    app = FastAPI()

    # CORSミドルウェアを追加してクロスオリジンリクエストを許可
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 依存性注入コンテナを使用するための設定
    app.state.container = container

    # 各エンドポイントのルーターを登録
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(areas.router)
    app.include_router(current.router)
    app.include_router(posts.router)
    app.include_router(batch.router)

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
