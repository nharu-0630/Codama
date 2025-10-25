"""Database client initialization."""

import googlemaps  # type: ignore
from supabase import create_client

from config.settings import settings

supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)
