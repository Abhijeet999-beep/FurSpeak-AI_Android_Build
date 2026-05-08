from pydantic import BaseModel
from typing import List, Optional, Any

class TimelineEntry(BaseModel):
    frame: int
    emotion: str

class DetectionResult(BaseModel):
    emotion: str
    confidence: float
    caption: str
    suggestion: str
    thumbnail_url: str = ""
    timeline: List[TimelineEntry] = []

class JobStatusResponse(BaseModel):
    job_id: str
    status: str
    result: Optional[DetectionResult] = None
    message: Optional[str] = None
