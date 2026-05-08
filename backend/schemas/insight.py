from pydantic import BaseModel


class InsightsResponse(BaseModel):
    """Emotion insight counts matching the canonical model taxonomy.
    
    Fields align with settings.EMOTION_CLASSES:
    relax, happy, angry, frown, alert
    """
    relax: int = 0
    happy: int = 0
    angry: int = 0
    frown: int = 0
    alert: int = 0
