import googlemaps  # type: ignore
from config.settings import settings
from openai import OpenAI
from supabase import create_client


class DatabaseClient:
    """データベース клиентаの抽象化"""

    def __init__(self):
        self._supabase = None
        self._gmaps = None
        self._openai = None

    @property
    def supabase(self):
        """Supabase клиентаを取得"""
        if self._supabase is None:
            self._supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        return self._supabase

    @property
    def gmaps(self):
        """Google Maps клиентаを取得"""
        if self._gmaps is None:
            self._gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)
        return self._gmaps

    @property
    def openai(self):
        """OpenAI клиентаを取得"""
        if self._openai is None:
            self._openai = OpenAI(api_key=settings.OPENAI_API_KEY)
        return self._openai


# シングルトンインスタンス
database_client = DatabaseClient()
