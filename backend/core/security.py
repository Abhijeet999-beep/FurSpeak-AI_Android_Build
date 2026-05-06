import os
import logging
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

logger = logging.getLogger("FurSpeak-Security")

security = HTTPBearer(auto_error=False)

# Environment gate: only "development" allows auth bypass.
# Production MUST have ENVIRONMENT=production set explicitly.
_ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
_IS_PRODUCTION = _ENVIRONMENT == "production"

try:
    import firebase_admin
    from firebase_admin import credentials, auth
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    if _IS_PRODUCTION:
        raise RuntimeError("FATAL: firebase-admin is required in production but not installed.")
    logger.warning("firebase-admin not installed. Auth bypass active for local development only.")

if FIREBASE_AVAILABLE and not firebase_admin._apps:
    try:
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin initialized with service account credentials.")
        elif _IS_PRODUCTION:
            raise RuntimeError(
                "FATAL: GOOGLE_APPLICATION_CREDENTIALS must be set in production. "
                "Cannot start without Firebase Admin credentials."
            )
        else:
            logger.warning("Skipping Firebase Admin init. Missing GOOGLE_APPLICATION_CREDENTIALS (dev mode).")
    except RuntimeError:
        raise  # Re-raise fatal errors
    except Exception as e:
        if _IS_PRODUCTION:
            raise RuntimeError(f"FATAL: Firebase Admin init failed in production: {e}")
        logger.warning(f"Firebase Admin init failed (dev mode): {e}")


async def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Security(security)) -> str:
    """Verify Firebase ID token and extract UID.

    In production: strictly enforces valid Firebase tokens.
    In development: falls back to a dev UID if Firebase is not configured.
    """
    token = credentials.credentials if credentials else None

    # ── PRODUCTION: strict enforcement, no bypass ──────────────────────
    if _IS_PRODUCTION:
        if not token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing authentication token.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        try:
            decoded_token = auth.verify_id_token(token)
            return decoded_token['uid']
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid authentication credentials: {str(e)}",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # ── DEVELOPMENT ONLY: allow bypass if Firebase is not configured ───
    if (
        not FIREBASE_AVAILABLE
        or not getattr(firebase_admin, '_apps', None)
        or not token
    ):
        logger.debug(f"[DEV AUTH] Bypassing auth (env={_ENVIRONMENT}). Token present: {token is not None}")
        return "development-uid-123"

    # Firebase IS configured in dev — still validate properly
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token['uid']
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
