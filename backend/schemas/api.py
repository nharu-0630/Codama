from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class APIArea(BaseModel):
    """エリア情報のAPIモデル"""

    id: int
    name: str


class APICell(BaseModel):
    """セル情報のAPIモデル"""

    id: int
    geo_hash: str
    location: tuple[float, float]


class APIPost(BaseModel):
    """投稿情報のAPIモデル（ユーザー投稿・LLM返信）"""

    uuid: UUID
    content: str
    location: tuple[float, float]
    replies: list["APIPost"] = []
    created_at: datetime


APIPost.update_forward_refs()  # type: ignore


class APIPrompt(BaseModel):
    """プロンプト情報のAPIモデル"""

    id: int
    prompt: str
    area_id: int
    created_at: datetime


class CurrentResponse(BaseModel):
    """現在位置エンドポイントのレスポンス"""

    area: APIArea
    cell: APICell


class PostsResponse(BaseModel):
    """投稿一覧エンドポイントのレスポンス"""

    posts: list[APIPost]


class CreatePostResponse(BaseModel):
    """投稿作成エンドポイントのレスポンス"""

    post: APIPost
    similar_posts: list[APIPost]


class SignupResponse(BaseModel):
    """サインアップエンドポイントのレスポンス"""

    access_token: str
    refresh_token: str
    user_id: str


class UpdatePromptResponse(BaseModel):
    """プロンプト更新エンドポイントのレスポンス"""

    success: bool


class CreatePostRequest(BaseModel):
    """投稿作成エンドポイントのリクエスト"""

    content: str
    lat: float
    lon: float
