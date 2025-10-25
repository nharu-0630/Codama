import googlemaps  # type: ignore
from openai import OpenAI
from supabase import create_client

from config.settings import settings

# Supabaseクライアントの初期化
supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

# Google Maps APIクライアントの初期化
gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)

# OpenAI APIクライアントの初期化
openai = OpenAI(api_key=settings.OPENAI_API_KEY)
