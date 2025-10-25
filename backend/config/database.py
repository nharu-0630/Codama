"""Database client initialization."""

import googlemaps  # type: ignore
from openai import OpenAI
from supabase import create_client

from config.settings import settings

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)
openai = OpenAI(api_key=settings.OPENAI_API_KEY)
