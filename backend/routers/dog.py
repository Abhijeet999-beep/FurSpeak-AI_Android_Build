from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from backend.core.database import get_db
from backend.core.dependencies import get_authenticated_user
from backend.schemas.base import BaseResponse
from backend.schemas.dog import DogCreate, DogUpdate, DogResponse
from backend.services.dog_service import DogService
from backend.models.user import User

router = APIRouter(prefix="/dogs", tags=["dogs"])

@router.post("/", response_model=BaseResponse)
async def create_dog(
    dog_in: DogCreate,
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    dog = await DogService.create_dog(db, user.id, dog_in)
    return BaseResponse.success(data=DogResponse.model_validate(dog).model_dump(), message="Dog profile created")

@router.get("/", response_model=BaseResponse)
async def get_dogs(
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    dogs = await DogService.get_dogs(db, user.id)
    dogs_data = [DogResponse.model_validate(d).model_dump() for d in dogs]
    return BaseResponse.success(data=dogs_data)

@router.get("/{dog_id}", response_model=BaseResponse)
async def get_dog(
    dog_id: str,
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    dog = await DogService.get_dog(db, user.id, dog_id)
    return BaseResponse.success(data=DogResponse.model_validate(dog).model_dump())

@router.delete("/{dog_id}", response_model=BaseResponse)
async def delete_dog(
    dog_id: str,
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    await DogService.delete_dog(db, user.id, dog_id)
    return BaseResponse.success(message="Dog profile deleted")
