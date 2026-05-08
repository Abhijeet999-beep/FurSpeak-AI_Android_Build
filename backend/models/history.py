from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from datetime import datetime
from backend.models.base import Base

class History(Base):
    __tablename__ = "history"

    id = Column(String, primary_key=True) # UUID
    user_id = Column(String, ForeignKey("users.id"))
    dog_id = Column(String, ForeignKey("dogs.id"), nullable=True)
    emotion = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    media_type = Column(String, nullable=False) # 'image' or 'video'
    thumbnail_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
