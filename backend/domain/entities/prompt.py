from dataclasses import dataclass
from datetime import datetime


@dataclass
class Prompt:
    """プロンプトエンティティ"""

    id: int
    prompt: str
    area_id: int
    created_at: datetime
