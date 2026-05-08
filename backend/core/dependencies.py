from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from backend.core.database import get_db
from backend.models.user import User
from backend.core.security import verify_firebase_token

async def get_current_user(
    uid: str = Depends(verify_firebase_token),
    db: AsyncSession = Depends(get_db)
):
    """
    Dependency that returns the current user object based on the Firebase UID.
    In development mode, verify_firebase_token may return 'development-uid-123'.
    """
    if uid == "development-uid-123":
        # Return a mock user for development bypass
        return User(id=uid, is_guest=True)
        
    # Attempt to fetch the real user from the database
    user = await db.get(User, uid)
    
    if user is None:
        # If user is valid in Firebase but not in our DB, we treat them as an on-the-fly user.
        # This can happen if the user just signed up but the sync hasn't completed.
        # We return a transient User object so detection can proceed.
        return User(id=uid, is_guest=False)
        
    return user

async def get_authenticated_user(user: User = Depends(get_current_user)):
    """Requires the user to NOT be a guest"""
    if user.is_guest:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Guest users cannot perform this action. Please sign in."
        )
    return user
