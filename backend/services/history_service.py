from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from backend.models.history import History
from backend.core.exceptions import FurSpeakException
import uuid


class HistoryService:
    @staticmethod
    async def add_history(
        db: AsyncSession,
        user_id: str,
        emotion: str,
        confidence: float,
        media_type: str,
        thumbnail_url: str = None,
        dog_id: str = None,
    ) -> History:
        record = History(
            id=str(uuid.uuid4()),
            user_id=user_id,
            dog_id=dog_id,
            emotion=emotion,
            confidence=confidence,
            media_type=media_type,
            thumbnail_url=thumbnail_url,
        )
        db.add(record)
        await db.commit()
        return record

    @staticmethod
    async def get_history(db: AsyncSession, user_id: str, limit: int = 50) -> list[History]:
        stmt = (
            select(History)
            .where(History.user_id == user_id)
            .order_by(History.created_at.desc())
            .limit(limit)
        )
        result = await db.execute(stmt)
        return result.scalars().all()

    @staticmethod
    async def delete_history(db: AsyncSession, user_id: str, history_id: str):
        stmt = select(History).where(History.user_id == user_id, History.id == history_id)
        result = await db.execute(stmt)
        record = result.scalar_one_or_none()
        if not record:
            raise FurSpeakException("NOT_FOUND", "History record not found", 404)
        await db.delete(record)
        await db.commit()

    @staticmethod
    async def get_insights(db: AsyncSession, user_id: str) -> dict:
        """
        H6 fix: Dynamically aggregates ALL emotions from the database
        instead of using a hardcoded mapping that doesn't match model output.
        
        Model classes: relax, happy, angry, frown, alert
        This now correctly counts all of them.
        """
        stmt = (
            select(History.emotion, func.count(History.id))
            .where(History.user_id == user_id)
            .group_by(History.emotion)
        )
        result = await db.execute(stmt)

        # Start with all known model emotions at zero
        from backend.core.config import settings

        counts = {emotion: 0 for emotion in settings.EMOTION_CLASSES}

        for row in result.all():
            emotion = row[0].lower()
            counts[emotion] = row[1]

        return counts
