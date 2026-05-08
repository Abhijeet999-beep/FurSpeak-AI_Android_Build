from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class DogCreate(BaseModel):
    name: str
    breed: str
    age: Optional[int] = None
    photo_url: Optional[str] = None

class DogUpdate(BaseModel):
    name: Optional[str] = None
    breed: Optional[str] = None
    age: Optional[int] = None
    photo_url: Optional[str] = None

class DogResponse(BaseModel):
    id: str
    user_id: str
    name: str
    breed: str
    age: Optional[int] = None
    photo_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
