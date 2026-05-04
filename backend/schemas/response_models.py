from pydantic import BaseModel
from typing import List, Optional

class TimelineEntry(BaseModel):
    frame: int
    emotion: str

class EmotionResponse(BaseModel):
    emotion: str
    confidence: float
    caption: str
    timeline: Optional[List[TimelineEntry]] = None
    timeline_summary: Optional[str] = None
    frame_sampled: Optional[int] = None
    processing_time: float
    timestamp: str
    imagePath: Optional[str] = None
    frame_image_path: Optional[str] = None
    frame_image_url: Optional[str] = None
    
    # Telemetry
    model_version: str
    request_source: str
