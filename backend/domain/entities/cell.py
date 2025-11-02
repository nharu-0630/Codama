from dataclasses import dataclass
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from domain.entities import Area


@dataclass
class Cell:
    """Cellエンティティ"""

    id: int
    geo_hash: str
    location: str
    area_id: int
    area: Optional["Area"] = None
