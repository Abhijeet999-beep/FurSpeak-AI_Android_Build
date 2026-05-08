from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from backend.schemas.auth import GoogleLoginRequest, TokenResponse, GuestTokenResponse, UserMeResponse
from backend.schemas.base import BaseResponse
from backend.services.auth_service import AuthService
from backend.core.dependencies import get_current_user
from backend.core.database import get_db
from backend.models.user import User
from backend.core.rate_limiter import get_rate_limiter
from backend.core.logging import logger

router = APIRouter(prefix="/auth", tags=["auth"])
auth_limiter = get_rate_limiter(10, 60)


@router.post("/google", response_model=BaseResponse, dependencies=[Depends(auth_limiter)])
async def google_login(request: GoogleLoginRequest, db: AsyncSession = Depends(get_db)):
    logger.info("Processing Google login request")
    # C2 fix: pass db session to auth service
    token_resp = await AuthService.verify_google_token(request.id_token, db)
    logger.info("Google login successful")
    return BaseResponse.success(data=token_resp, message="Login successful")


@router.post("/guest", response_model=BaseResponse, dependencies=[Depends(auth_limiter)])
async def guest_login():
    logger.info("Processing Guest login request")
    token_resp = await AuthService.generate_guest_token()
    logger.info("Guest login successful")
    return BaseResponse.success(data=token_resp, message="Guest session created")


@router.get("/me", response_model=BaseResponse, dependencies=[Depends(auth_limiter)])
async def get_me(user: User = Depends(get_current_user)):
    logger.info(f"Retrieving user details for {user.id}")
    # C1 fix: user is a User ORM object, access via attributes not dict methods
    return BaseResponse.success(
        data=UserMeResponse(
            id=user.id,
            phone_number=getattr(user, "phone_number", None),
            email=getattr(user, "email", None),
            is_guest=user.is_guest,
        ).model_dump()
    )
