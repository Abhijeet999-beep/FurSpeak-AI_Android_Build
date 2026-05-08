import firebase_admin
from firebase_admin import auth
from backend.core.config import settings
from backend.models.user import User
from backend.core.exceptions import FurSpeakException
from sqlalchemy.ext.asyncio import AsyncSession
import jwt
from datetime import datetime, timedelta
import uuid
from backend.core.logging import logger

class AuthService:
    
    @staticmethod
    def _create_jwt(user_id: str, role: str) -> str:
        expire = datetime.utcnow() + timedelta(minutes=settings.GUEST_TOKEN_EXPIRE_MINUTES)
        payload = {
            "sub": user_id,
            "role": role,
            "exp": expire
        }
        return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    @classmethod
    async def verify_google_token(cls, id_token: str, db: AsyncSession) -> dict:
        try:
            decoded_token = auth.verify_id_token(id_token)
            uid = decoded_token['uid']
            email = decoded_token.get('email')
            
            # Upsert User
            user = await db.get(User, uid)
            if not user:
                user = User(id=uid, email=email, is_guest=False)
                db.add(user)
                await db.commit()
                
            access_token = cls._create_jwt(uid, "auth")
            return {"access_token": access_token, "refresh_token": "dummy_refresh", "token_type": "bearer"}
        except Exception as e:
            logger.error(f"Google Token verification failed: {e}")
            raise FurSpeakException("AUTH_FAILED", "Invalid Google ID token", 401)

    @classmethod
    async def generate_guest_token(cls) -> dict:
        guest_uid = f"guest_{uuid.uuid4().hex}"
        access_token = cls._create_jwt(guest_uid, "guest")
        return {"access_token": access_token, "token_type": "bearer"}
