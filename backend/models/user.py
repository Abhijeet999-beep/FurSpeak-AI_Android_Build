from sqlalchemy import Column, String, Boolean, DateTime
from datetime import datetime
from backend.models.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True) # UUID or Firebase UID
    phone_number = Column(String, nullable=True, unique=True)
    email = Column(String, nullable=True, unique=True)
    is_guest = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
