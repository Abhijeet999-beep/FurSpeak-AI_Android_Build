from pydantic import BaseModel
from typing import Optional

class GoogleLoginRequest(BaseModel):
    id_token: str

class PhoneOTPRequest(BaseModel):
    phone: str

class PhoneOTPVerifyRequest(BaseModel):
    phone: str
    code: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class GuestTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserMeResponse(BaseModel):
    id: str
    phone_number: Optional[str] = None
    email: Optional[str] = None
    is_guest: bool
