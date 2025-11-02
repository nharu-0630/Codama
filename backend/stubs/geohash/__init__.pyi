"""Type stubs for geohash library."""
from typing import Tuple, List

def encode(latitude: float, longitude: float, precision: int = ...) -> str:
    """Encode latitude and longitude to geohash string."""
    ...

def decode(geohash: str) -> Tuple[float, float]:
    """Decode geohash string to latitude and longitude."""
    ...

def neighbors(geohash: str) -> List[str]:
    """Get neighboring geohashes."""
    ...
