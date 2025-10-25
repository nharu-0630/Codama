import yaml
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
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

    # 各エンドポイントのルーターを登録
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(areas.router)
    app.include_router(current.router)
    app.include_router(posts.router)
    app.include_router(batch.router)

    # OpenAPI仕様を生成してYAMLファイルに保存
    schema = get_openapi(
        title=app.title,
        version=app.version,
        openapi_version=app.openapi_version,
        description=app.description,
        routes=app.routes,
    )
    with open("openapi.yaml", "w") as f:
        yaml.dump(schema, f, default_flow_style=False, allow_unicode=True)

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
