import firebase_admin
from firebase_admin import storage
from backend.core.config import settings
import logging
import uuid
import os
import asyncio
from datetime import timedelta

logger = logging.getLogger("FurSpeak-StorageService")


class StorageService:
    """Firebase Storage upload service.
    
    H5 fix: Removed duplicate Firebase initialization.
    Firebase Admin SDK is initialized once in security.py at import time.
    This service only checks that an app exists and uses it.
    """

    @classmethod
    def _ensure_firebase(cls):
        """Verify Firebase Admin is initialized. Does NOT re-initialize."""
        if not firebase_admin._apps:
            logger.warning(
                "Firebase Admin SDK not initialized. "
                "Storage uploads will fail. Ensure security.py loads before this service."
            )
            return False
        return True

    @classmethod
    async def upload_thumbnail(cls, local_path: str, user_id: str, job_id: str = None) -> str | None:
        if not cls._ensure_firebase():
            return None

        try:
            loop = asyncio.get_running_loop()

            def _upload():
                bucket = storage.bucket(settings.FIREBASE_STORAGE_BUCKET)
                ext = os.path.splitext(local_path)[-1]
                blob_name = f"thumbnails/{user_id}/{uuid.uuid4().hex}{ext}"
                blob = bucket.blob(blob_name)
                blob.upload_from_filename(local_path)
                # Use signed URLs for production security (valid for 7 days)
                return blob.generate_signed_url(expiration=timedelta(days=7))

            return await loop.run_in_executor(None, _upload)
        except Exception as e:
            logger.warning(f"[STORAGE] thumbnail upload failed gracefully: {e}")
            return None

    @classmethod
    async def upload_dog_photo(cls, user_id: str, local_path: str) -> str | None:
        if not cls._ensure_firebase():
            return None

        try:
            loop = asyncio.get_running_loop()

            def _upload():
                bucket = storage.bucket(settings.FIREBASE_STORAGE_BUCKET)
                ext = os.path.splitext(local_path)[-1]
                blob_name = f"profiles/{user_id}/{uuid.uuid4().hex}{ext}"
                blob = bucket.blob(blob_name)
                blob.upload_from_filename(local_path)
                blob.make_public()
                return blob.public_url

            return await loop.run_in_executor(None, _upload)
        except Exception as e:
            logger.warning(f"[STORAGE] dog photo upload failed gracefully: {e}")
            return None
