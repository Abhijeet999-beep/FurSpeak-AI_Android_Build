from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class HistoryResponse(BaseModel):
    id: str
    dog_id: Optional[str] = None
    emotion: str
    confidence: float
    media_type: str
    thumbnail_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
