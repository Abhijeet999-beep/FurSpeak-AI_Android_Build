import os
import logging
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from backend.core.config import settings

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
    # We will log this below in the FIREBASE_AVAILABLE check

if FIREBASE_AVAILABLE:
    logger.info(f"FIREBASE_AVAILABLE is True. Initialized apps: {list(firebase_admin._apps.keys())}")
    
    if not firebase_admin._apps:
        try:
            # 1. Try JSON string from ENV (Priority 1 — Best for Railway/Cloud)
            cred_json = settings.FIREBASE_CREDENTIALS_JSON
            if cred_json:
                import json
                try:
                    cred_dict = json.loads(cred_json)
                    cred = credentials.Certificate(cred_dict)
                    firebase_admin.initialize_app(cred)
                    logger.info("Firebase Admin initialized successfully from FIREBASE_CREDENTIALS_JSON.")
                except Exception as e:
                    logger.error(f"Failed to parse FIREBASE_CREDENTIALS_JSON: {e}")

            # 2. Try file path (Priority 2 — Fallback if JSON string failed or not set)
            if not firebase_admin._apps:
                cred_path = getattr(settings, "GOOGLE_APPLICATION_CREDENTIALS", None)
                if not cred_path:
                    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
                if not cred_path:
                    cred_path = settings.FIREBASE_CREDENTIALS_PATH
                
                if cred_path and os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    logger.info(f"Firebase Admin initialized successfully from file: {cred_path}")
                elif _IS_PRODUCTION:
                    logger.error("PRODUCTION ERROR: Missing credentials (neither FIREBASE_CREDENTIALS_JSON nor file path set).")
                    raise RuntimeError(
                        "FATAL: Firebase credentials must be set in production. "
                        "Set FIREBASE_CREDENTIALS_JSON or GOOGLE_APPLICATION_CREDENTIALS."
                    )
                else:
                    logger.warning(f"Skipping Firebase Admin init. Credentials not found (dev mode).")
        except RuntimeError:
            raise  # Re-raise fatal errors
        except Exception as e:
            if _IS_PRODUCTION:
                logger.error(f"PRODUCTION ERROR: Firebase init failed: {e}")
                raise RuntimeError(f"FATAL: Firebase Admin init failed in production: {e}")
            logger.warning(f"Firebase Admin init failed (dev mode): {e}")
    else:
        logger.info("Firebase Admin already initialized.")
else:
    logger.warning("firebase-admin library NOT FOUND in this environment (FIREBASE_AVAILABLE is False).")


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
