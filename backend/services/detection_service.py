import os
import uuid
import time
import shutil
import tempfile
import asyncio
from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from collections import OrderedDict

from backend.core.config import settings
from backend.core.cache import compute_sha256
from backend.core.worker import job_queue
from backend.core.exceptions import FurSpeakException
from backend.utils.media_validator import validate_magic_bytes
from backend.utils.temp_cleanup import safe_remove
from backend.models.job import Job
from backend.models.user import User
from backend.schemas.detection import DetectionResult, JobStatusResponse
from backend.services.image_service import ImageService
from backend.services.video_service import VideoService
from backend.services.storage_service import StorageService
from backend.services.history_service import HistoryService
from backend.core.logging import logger

# ── Duplicate request cache ──────────────────────────────────────────
_DUPLICATE_CACHE = OrderedDict()
_DUPLICATE_TTL = 10
_MAX_CACHE_SIZE = 50
_LAST_SIZE_CHECK_TIME = 0
_SIZE_CHECK_INTERVAL = 60  # Only walk the disk once per minute


def _check_duplicate(request_hash: str) -> str | None:
    now = time.time()
    # Prune expired entries
    expired = [k for k, v in _DUPLICATE_CACHE.items() if now - v["timestamp"] > _DUPLICATE_TTL]
    for k in expired:
        del _DUPLICATE_CACHE[k]

    if request_hash in _DUPLICATE_CACHE:
        _DUPLICATE_CACHE.move_to_end(request_hash)
        return _DUPLICATE_CACHE[request_hash]["job_id"]

    return None


def _set_duplicate(request_hash: str, job_id: str):
    _DUPLICATE_CACHE[request_hash] = {"job_id": job_id, "timestamp": time.time()}
    if len(_DUPLICATE_CACHE) > _MAX_CACHE_SIZE:
        _DUPLICATE_CACHE.popitem(last=False)


class DetectionService:

    @staticmethod
    async def _enforce_temp_size_cap():
        """Reject requests when temp storage exceeds 500 MB. Optimized to not block event loop."""
        global _LAST_SIZE_CHECK_TIME
        now = time.time()

        # Skip if we checked recently
        if now - _LAST_SIZE_CHECK_TIME < _SIZE_CHECK_INTERVAL:
            return

        def _get_size():
            total_size = 0
            try:
                for dp, _, fn in os.walk(settings.TEMP_DIR):
                    for f in fn:
                        fp = os.path.join(dp, f)
                        if not os.path.islink(fp):
                            total_size += os.path.getsize(fp)
            except OSError:
                pass # Directory might be being cleaned up
            return total_size

        total_size = await asyncio.to_thread(_get_size)
        _LAST_SIZE_CHECK_TIME = time.time()

        if total_size > 500 * 1024 * 1024:  # 500 MB
            logger.warning(f"Temp storage threshold reached ({total_size / 1024 / 1024:.1f} MB). Triggering cleanup.")
            from backend.utils.temp_cleanup import cleanup_stale_temp_files
            await asyncio.to_thread(cleanup_stale_temp_files, settings.TEMP_DIR, 3600)  # Clear stale files older than 1h
            
            # Reset counter so next request forces a re-check after cleanup
            _LAST_SIZE_CHECK_TIME = 0

    @staticmethod
    async def process_image_sync(file: UploadFile, user: User, db: AsyncSession) -> DetectionResult:
        await DetectionService._enforce_temp_size_cap()
        # 1. Safe stream to temp
        fd, temp_path = tempfile.mkstemp(dir=settings.TEMP_DIR, suffix=".jpg")
        os.close(fd)

        try:
            def _save():
                with open(temp_path, "wb") as f_out:
                    shutil.copyfileobj(file.file, f_out)
            await asyncio.to_thread(_save)

            if os.path.getsize(temp_path) > settings.MAX_FILE_SIZE_BYTES:
                raise FurSpeakException("FILE_TOO_LARGE", "File exceeds max size.", 413)

            if not validate_magic_bytes(temp_path):
                raise FurSpeakException("CORRUPT_MEDIA", "File verification failed.", 400)

            # 2. Run Image Service via GPU worker queue (H10 fix: no longer blocks event loop)
            loop = asyncio.get_running_loop()
            future = loop.create_future()
            image_job_id = f"img_{uuid.uuid4().hex[:8]}"

            await job_queue.put((image_job_id, future, ImageService.process_image, (temp_path, image_job_id), {}))

            try:
                result: DetectionResult = await asyncio.wait_for(future, timeout=settings.IMAGE_TIMEOUT_SECONDS)
            except asyncio.TimeoutError:
                raise FurSpeakException("TIMEOUT", "Image processing took too long.", 504)

            # 3. Add to history if authenticated
            if not user.is_guest:
                await HistoryService.add_history(
                    db=db,
                    user_id=user.id,
                    emotion=result.emotion,
                    confidence=result.confidence,
                    media_type="image",
                    thumbnail_url=result.thumbnail_url,
                )

            return result

        finally:
            safe_remove(temp_path)

    @staticmethod
    async def process_video_async(
        file: UploadFile, user: User, db: AsyncSession, base_url: str
    ) -> JobStatusResponse:
        t0_total = time.perf_counter()
        await DetectionService._enforce_temp_size_cap()
        fd, temp_path = tempfile.mkstemp(dir=settings.TEMP_DIR, suffix=".mp4")
        os.close(fd)

        try:
            t0_upload = time.perf_counter()
            def _save():
                with open(temp_path, "wb") as f_out:
                    shutil.copyfileobj(file.file, f_out)
            await asyncio.to_thread(_save)
            logger.info(f"[TIMING] process_video_async -> File Write: {time.perf_counter() - t0_upload:.4f}s")

            if os.path.getsize(temp_path) > settings.MAX_FILE_SIZE_BYTES:
                safe_remove(temp_path)
                raise FurSpeakException("FILE_TOO_LARGE", "File exceeds max size.", 413)

            if not validate_magic_bytes(temp_path):
                safe_remove(temp_path)
                raise FurSpeakException("CORRUPT_MEDIA", "File verification failed.", 400)

            # ── Video validation & optional compression (M5 integration) ──
            try:
                t0_norm = time.perf_counter()
                from backend.utils.media_processor import MediaProcessor

                temp_path = await asyncio.to_thread(MediaProcessor.validate_and_normalize_video, temp_path)
                logger.info(f"[TIMING] process_video_async -> Normalization: {time.perf_counter() - t0_norm:.4f}s")
            except FurSpeakException:
                safe_remove(temp_path)
                raise
            except Exception as e:
                logger.warning(f"Video normalization skipped (ffmpeg unavailable?): {e}")

            t0_hash = time.perf_counter()
            request_hash = await asyncio.to_thread(compute_sha256, temp_path)
            logger.info(f"[TIMING] process_video_async -> Hash compute: {time.perf_counter() - t0_hash:.4f}s")
            logger.info(f"[TIMING] process_video_async -> Total Pre-processing: {time.perf_counter() - t0_total:.4f}s")

            # Enforce max 2 active video jobs per user
            job_user_id = user.id if not user.is_guest else None
            if job_user_id:
                stmt_active = select(Job).where(Job.user_id == job_user_id, Job.status == "processing")
                active_jobs = (await db.execute(stmt_active)).scalars().all()
                if len(active_jobs) >= 2:
                    safe_remove(temp_path)
                    raise FurSpeakException("TOO_MANY_JOBS", "You can only have 2 active video processing jobs at a time.", 409)

            # Check LRU Cache
            cached_job_id = _check_duplicate(request_hash)
            if cached_job_id:
                safe_remove(temp_path)
                return JobStatusResponse(job_id=cached_job_id, status="processing")

            # Check for existing job for idempotency in DB (including failed/expired to avoid UNIQUE constraint violation)
            stmt = select(Job).where(Job.request_hash == request_hash)
            existing_job = (await db.execute(stmt)).scalars().first()

            if existing_job:
                if existing_job.status in ["processing", "completed"]:
                    safe_remove(temp_path)
                    _set_duplicate(request_hash, existing_job.id)
                    return JobStatusResponse(
                        job_id=existing_job.id,
                        status=existing_job.status,
                        result=DetectionResult(**existing_job.result_json) if existing_job.result_json and existing_job.status == "completed" else None,
                    )
                # Retry: reuse existing failed/expired job
                job_id = existing_job.id
                existing_job.status = "processing"
                existing_job.result_json = None
                db.add(existing_job)
            else:
                job_id = uuid.uuid4().hex

            # Subfolder Isolation
            job_temp_dir = os.path.join(settings.TEMP_DIR, job_id)
            os.makedirs(job_temp_dir, exist_ok=True)
            isolated_temp_path = os.path.join(job_temp_dir, "video.mp4")
            if os.path.exists(isolated_temp_path):
                safe_remove(isolated_temp_path)
            await asyncio.to_thread(shutil.move, temp_path, isolated_temp_path)
            temp_path = isolated_temp_path

            if not existing_job:
                # H2 fix: guest users get a deterministic non-null user_id
                job_user_id = user.id if not user.is_guest else None
                new_job = Job(
                    id=job_id,
                    user_id=job_user_id,
                    status="processing",
                    request_hash=request_hash,
                )
                db.add(new_job)

            _set_duplicate(request_hash, job_id)
            await db.commit()

            # Fire-and-forget background task (survives request cancellation)
            asyncio.create_task(DetectionService._video_worker_task(job_id, temp_path, request_hash, user))

            return JobStatusResponse(job_id=job_id, status="processing")

        except Exception as e:
            safe_remove(temp_path)
            raise e

    @staticmethod
    async def _video_worker_task(job_id: str, temp_path: str, request_hash: str, user: User):
        """Background task for video processing. Owns its own DB session."""
        from backend.core.database import AsyncSessionLocal

        loop = asyncio.get_running_loop()
        future = loop.create_future()

        # Enqueue for single GPU worker
        await job_queue.put((job_id, future, VideoService.process_video, (temp_path, job_id), {}))

        try:
            # Wait for single-worker to finish this job
            result_tuple = await future
            result: DetectionResult = result_tuple[0]
            best_frame_path = result_tuple[1]

            # Upload thumbnail if available
            thumbnail_url = None
            if best_frame_path and os.path.exists(best_frame_path):
                uid_str = user.id if not user.is_guest else "guest"
                thumbnail_url = await StorageService.upload_thumbnail(best_frame_path, uid_str, job_id)
                result.thumbnail_url = thumbnail_url or ""
                safe_remove(best_frame_path)

            async with AsyncSessionLocal() as db:
                job = await db.get(Job, job_id)
                if job:
                    job.status = "completed"
                    job.result_json = result.model_dump()
                    db.add(job)

                    if not user.is_guest:
                        await HistoryService.add_history(
                            db=db,
                            user_id=user.id,
                            emotion=result.emotion,
                            confidence=result.confidence,
                            media_type="video",
                            thumbnail_url=result.thumbnail_url,
                        )

                    await db.commit()

        except Exception as e:
            logger.error(f"Job {job_id} failed: {e}", exc_info=True)
            async with AsyncSessionLocal() as db:
                job = await db.get(Job, job_id)
                if job:
                    job.status = "failed"
                    job.result_json = {"error": str(e)}
                    db.add(job)
                    await db.commit()
        finally:
            safe_remove(temp_path)
            job_temp_dir = os.path.dirname(temp_path)
            if os.path.exists(job_temp_dir) and job_temp_dir != settings.TEMP_DIR:
                try:
                    shutil.rmtree(job_temp_dir, ignore_errors=True)
                except OSError:
                    pass

    @staticmethod
    async def get_job_status(job_id: str, user: User, db: AsyncSession) -> JobStatusResponse:
        job = await db.get(Job, job_id)
        if not job:
            raise FurSpeakException("NOT_FOUND", "Job not found", 404)

        if job.user_id and not user.is_guest and job.user_id != user.id:
            raise FurSpeakException("UNAUTHORIZED", "Not your job", 403)

        result_obj = None
        if job.status == "completed" and job.result_json:
            result_obj = DetectionResult(**job.result_json)

        msg = None
        if job.status == "failed" and job.result_json:
            msg = job.result_json.get("error", "Unknown error")

        # ── Expired job handling: remap to failed with retry-friendly message ──
        if job.status == "expired":
            return JobStatusResponse(
                job_id=job.id,
                status="failed",
                result=None,
                message="This scan took too long and expired. Please try again.",
            )

        return JobStatusResponse(
            job_id=job.id,
            status=job.status,
            result=result_obj,
            message=msg,
        )
