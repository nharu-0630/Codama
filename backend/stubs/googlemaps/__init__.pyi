"""Type stubs for googlemaps library."""
from typing import Any, List, Dict

class Client:
    """Google Maps Client."""

    def __init__(self, key: str) -> None: ...

    def reverse_geocode(
        self,
        latlng: tuple[float, float],
        language: str = ...,
    ) -> List[Dict[str, Any]]: ...
