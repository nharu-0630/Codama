from fastapi import Header, HTTPException
from infrastructure.clients.database_client import database_client
from supabase_auth import User


async def get_current_user(authorization: str = Header(...)) -> User:
    """認証ヘッダーから現在のユーザーを取得"""
    try:
        # Bearer トークンの形式を確認
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header")

        # トークンを抽出
        token = authorization.replace("Bearer ", "")

        # Supabaseでトークンを検証してユーザー情報を取得
        user_response = database_client.supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

        return user_response.user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")
