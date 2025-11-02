import googlemaps

from config.settings import settings


class MapsClient:
    """Google Maps クライアントの抽象化"""

    def __init__(self) -> None:
        self._gmaps: googlemaps.Client | None = None

    @property
    def gmaps(self) -> googlemaps.Client:
        """Google Maps クライアントを取得"""
        if self._gmaps is None:
            self._gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)
        return self._gmaps


# シングルトンインスタンス
maps_client = MapsClient()
