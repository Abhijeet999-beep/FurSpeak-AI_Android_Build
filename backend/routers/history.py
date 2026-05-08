from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from backend.core.database import get_db
from backend.core.dependencies import get_authenticated_user
from backend.schemas.base import BaseResponse
from backend.schemas.history import HistoryResponse
from backend.schemas.insight import InsightsResponse
from backend.services.history_service import HistoryService
from backend.models.user import User

router = APIRouter(prefix="/history", tags=["history"])

@router.get("/", response_model=BaseResponse)
async def get_history(
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    history = await HistoryService.get_history(db, user.id)
    history_data = [HistoryResponse.model_validate(h).model_dump() for h in history]
    return BaseResponse.success(data=history_data)

@router.delete("/{history_id}", response_model=BaseResponse)
async def delete_history(
    history_id: str,
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    await HistoryService.delete_history(db, user.id, history_id)
    return BaseResponse.success(message="History record deleted")

@router.get("/insights", response_model=BaseResponse)
async def get_insights(
    user: User = Depends(get_authenticated_user),
    db: AsyncSession = Depends(get_db)
):
    insights = await HistoryService.get_insights(db, user.id)
    return BaseResponse.success(data=InsightsResponse(**insights).model_dump())
