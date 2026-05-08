from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from datetime import datetime
from backend.models.base import Base

class Dog(Base):
    __tablename__ = "dogs"

    id = Column(String, primary_key=True) # UUID
    user_id = Column(String, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    breed = Column(String, nullable=False)
    age = Column(Integer, nullable=True)
    photo_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
