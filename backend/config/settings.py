"""Application settings and configuration."""

import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Application settings."""

    GEO_HASH_PRECISION: int = int(os.environ.get("GEO_HASH_PRECISION", 7))
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
    SUPABASE_KEY: str = os.environ.get("SUPABASE_KEY", "")
    GOOGLE_MAPS_API_KEY: str = os.environ.get("GOOGLE_MAPS_API_KEY", "")
    OPENAI_API_KEY: str = os.environ.get("OPENAI_API_KEY", "")


settings = Settings()
