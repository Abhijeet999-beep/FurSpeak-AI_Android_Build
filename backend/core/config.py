import os
import logging
from pydantic_settings import BaseSettings

logger = logging.getLogger("FurSpeak-Config")

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

_DEV_JWT_SECRET = "super-secret-key-for-dev"


class Settings(BaseSettings):
    DEBUG_VISUAL: bool = False
    TEMP_DIR: str = os.path.join(BASE_DIR, "temp")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "production")

    # YOLO Model paths
    DOG_DETECTOR_MODEL_PATH: str = os.path.join(BASE_DIR, "ml", "weights", "yolov8m.pt")
    BEHAVIOR_MODEL_PATH: str = os.path.join(BASE_DIR, "ml", "weights", "best.pt")

    # Strict Video Input Rules
    MAX_VIDEO_DURATION_SECONDS: int = 20
    MAX_FILE_SIZE_BYTES: int = 200 * 1024 * 1024  # 200 MB
    MAX_RESOLUTION_HEIGHT: int = 720

    # Internal Processing Limits
    MAX_FRAMES_TO_PROCESS: int = 30
    MAX_TIMELINE_LENGTH: int = 20

    # Concurrency & Timeouts
    IMAGE_TIMEOUT_SECONDS: int = 10
    VIDEO_JOB_TIMEOUT_SECONDS: int = 180

    # DB & Firebase Config
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./furspeak.db")
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)
    elif DATABASE_URL.startswith("postgresql://"):
        DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-adminsdk.json")
    FIREBASE_STORAGE_BUCKET: str = os.getenv("FIREBASE_STORAGE_BUCKET", "furspeak-4ddd4.appspot.com")
    FIREBASE_CREDENTIALS_JSON: str | None = os.getenv("FIREBASE_CREDENTIALS_JSON")

    JWT_SECRET: str = os.getenv("JWT_SECRET", _DEV_JWT_SECRET)
    JWT_ALGORITHM: str = "HS256"
    GUEST_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day
    SENTRY_DSN: str | None = os.getenv("SENTRY_DSN")
    DISABLE_APP_CHECK: bool = os.getenv("DISABLE_APP_CHECK", "false").lower() == "true"

    MODEL_VERSION: str = "yolov8m-v1-behavior-beta"

    # Canonical emotion labels emitted by the behavior model.
    # Single source of truth for model → UI → insights mapping.
    EMOTION_CLASSES: list = ['relax', 'happy', 'angry', 'frown', 'alert']

    class Config:
        env_file = ".env"
        extra = "ignore"

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "production"


settings = Settings()

# ── Production safety gates ─────────────────────────────────────────
if settings.is_production:
    if settings.JWT_SECRET == _DEV_JWT_SECRET:
        raise RuntimeError(
            "FATAL: JWT_SECRET is set to the default development value. "
            "You MUST set a secure JWT_SECRET environment variable in production."
        )
    if len(settings.JWT_SECRET) < 32:
        raise RuntimeError(
            "FATAL: JWT_SECRET must be at least 32 characters in production."
        )

# Ensure base directories exist
os.makedirs(settings.TEMP_DIR, exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, "ml", "weights"), exist_ok=True)
