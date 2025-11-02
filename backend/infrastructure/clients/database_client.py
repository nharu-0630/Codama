from supabase import create_client

from config.settings import settings


class DatabaseClient:
    """データベースクライアントの抽象化"""

    def __init__(self):
        self._supabase = None

    @property
    def supabase(self):
        """Supabase クライアントを取得"""
        if self._supabase is None:
            self._supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        return self._supabase


# シングルトンインスタンス
database_client = DatabaseClient()
