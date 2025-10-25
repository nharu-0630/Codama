"""Authentication utility functions."""

from fastapi import Header, HTTPException
from supabase_auth import User

from config.database import supabase


async def get_current_user(authorization: str = Header(...)) -> User:
    """Get current authenticated user from authorization header."""
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header")
        token = authorization.replace("Bearer ", "")
        user_response = supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        return user_response.user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")
