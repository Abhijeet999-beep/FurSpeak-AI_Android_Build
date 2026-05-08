from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from backend.models.dog import Dog
from backend.schemas.dog import DogCreate, DogUpdate
from backend.core.exceptions import FurSpeakException
import uuid

class DogService:
    @staticmethod
    async def create_dog(db: AsyncSession, user_id: str, dog_in: DogCreate) -> Dog:
        dog_id = str(uuid.uuid4())
        dog = Dog(
            id=dog_id,
            user_id=user_id,
            name=dog_in.name,
            breed=dog_in.breed,
            age=dog_in.age,
            photo_url=dog_in.photo_url
        )
        db.add(dog)
        await db.commit()
        await db.refresh(dog)
        return dog

    @staticmethod
    async def get_dogs(db: AsyncSession, user_id: str) -> list[Dog]:
        stmt = select(Dog).where(Dog.user_id == user_id)
        result = await db.execute(stmt)
        return result.scalars().all()

    @staticmethod
    async def get_dog(db: AsyncSession, user_id: str, dog_id: str) -> Dog:
        stmt = select(Dog).where(Dog.user_id == user_id, Dog.id == dog_id)
        result = await db.execute(stmt)
        dog = result.scalar_one_or_none()
        if not dog:
            raise FurSpeakException("NOT_FOUND", "Dog not found", 404)
        return dog

    @staticmethod
    async def delete_dog(db: AsyncSession, user_id: str, dog_id: str):
        dog = await DogService.get_dog(db, user_id, dog_id)
        await db.delete(dog)
        await db.commit()
