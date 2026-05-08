from fastapi import APIRouter, Depends, UploadFile, File, Request
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.core.dependencies import get_current_user
from backend.core.rate_limiter import get_rate_limiter
from backend.schemas.base import BaseResponse
from backend.services.detection_service import DetectionService
from backend.models.user import User

router = APIRouter(prefix="/detect", tags=["detection"])

image_limiter = get_rate_limiter(12, 60)
video_limiter = get_rate_limiter(5, 60)
polling_limiter = get_rate_limiter(30, 60)

router = APIRouter(prefix="/detect", tags=["detection"])

@router.post("/image", response_model=BaseResponse, dependencies=[Depends(image_limiter)])
async def detect_image(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await DetectionService.process_image_sync(file, user, db)
    return BaseResponse.success(data=result.model_dump())

@router.post("/video", response_model=BaseResponse, dependencies=[Depends(video_limiter)])
async def detect_video(
    request: Request,
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    base_url = str(request.base_url).rstrip('/')
    job_resp = await DetectionService.process_video_async(file, user, db, base_url)
    return BaseResponse.success(data=job_resp.model_dump(), message="Processing started")

@router.get("/status/{job_id}", response_model=BaseResponse, dependencies=[Depends(polling_limiter)])
async def get_status(
    job_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    job_resp = await DetectionService.get_job_status(job_id, user, db)
    return BaseResponse.success(data=job_resp.model_dump())
