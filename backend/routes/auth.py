"""Authentication routes."""

from fastapi import APIRouter, HTTPException

from config.database import supabase
from model import SignupResponse

router = APIRouter(prefix="/signup", tags=["auth"])


@router.post("", response_model=SignupResponse)
async def signup():
    """Create an anonymous user session."""
    try:
        auth_response = supabase.auth.sign_in_anonymously()
        if not auth_response.session:
            raise HTTPException(
                status_code=500, detail="Failed to create anonymous session"
            )
        if not auth_response.user:
            raise HTTPException(
                status_code=500, detail="Failed to create anonymous user"
            )
        return SignupResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sign up: {str(e)}")
