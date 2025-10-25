from config.database import supabase
from fastapi import APIRouter, HTTPException
from schemas.api import SignupResponse

router = APIRouter(prefix="/signup", tags=["auth"])


@router.post("", response_model=SignupResponse)
async def signup():
    """匿名ユーザーとしてサインアップ"""
    try:
        # Supabaseで匿名認証を実行
        auth_response = supabase.auth.sign_in_anonymously()

        # セッションの作成を確認
        if not auth_response.session:
            raise HTTPException(
                status_code=500, detail="Failed to create anonymous session"
            )

        # ユーザーの作成を確認
        if not auth_response.user:
            raise HTTPException(
                status_code=500, detail="Failed to create anonymous user"
            )

        # トークンとユーザーIDを返却
        return SignupResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sign up: {str(e)}")
