from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from backend.core.config import settings
from backend.core.exceptions import FurSpeakException, furspeak_exception_handler
from backend.core.worker import gpu_worker
from backend.routers import auth, dog, history, detection
from backend.core.model_loader import model_loader
from backend.utils.temp_cleanup import cleanup_stale_temp_files
from backend.core import security
from backend.core.database import engine
from backend.models import Base
import cv2

# Set OpenCV thread limit globally to prevent memory spikes in Docker/Cloud Run
cv2.setNumThreads(1)
import asyncio
import os
import uuid
from backend.core.logging import logger, trace_id_var, endpoint_var, method_var
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        integrations=[FastApiIntegration()],
        traces_sample_rate=0.1,
        environment=settings.ENVIRONMENT,
    )
    logger.info("Sentry initialized successfully.")

app = FastAPI(title="FurSpeak AI")
app.add_exception_handler(FurSpeakException, furspeak_exception_handler)

# Prometheus Metrics
try:
    from prometheus_fastapi_instrumentator import Instrumentator
    Instrumentator().instrument(app).expose(app, endpoint="/metrics")
    logger.info("Prometheus metrics initialized at /metrics")
except Exception as e:
    logger.warning(f"Failed to initialize Prometheus metrics: {e}")

# CORS Configuration
# CORS Configuration
origins = settings.ALLOWED_ORIGINS
# Production safety: Credentials + Wildcard is forbidden by many browsers and risky
if settings.is_production and "*" in origins:
    logger.warning("CORS: Wildcard origin detected in production. Restricting to empty list to prevent credential risk.")
    origins = [o for o in origins if o != "*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def request_tracing_middleware(request: Request, call_next):
    import time
    import psutil
    import os

    trace_id = str(uuid.uuid4())
    trace_id_var.set(trace_id)
    endpoint_var.set(request.url.path)
    method_var.set(request.method)
    
    start_time = time.perf_counter()
    process = psutil.Process(os.getpid())
    start_ram = process.memory_info().rss / 1024 / 1024

    response = await call_next(request)

    end_ram = process.memory_info().rss / 1024 / 1024
    process_time = time.perf_counter() - start_time
    
    if request.url.path not in ["/health", "/ping", "/metrics"]:
        logger.info(f"[TELEMETRY] {request.method} {request.url.path} | Time: {process_time:.4f}s | RAM Delta: {end_ram - start_ram:+.1f}MB | RAM Total: {end_ram:.1f}MB")

    response.headers["X-Trace-ID"] = trace_id
    response.headers["X-Process-Time"] = str(process_time)
    return response

@app.middleware("http")
async def limit_upload_size(request: Request, call_next):
    if request.headers.get("content-length"):
        try:
            size = int(request.headers.get("content-length"))
            if size > 15 * 1024 * 1024:
                return JSONResponse(
                    {"success": False, "error_code": "FILE_TOO_LARGE", "message": "Upload exceeds 15 MB limit."},
                    status_code=413,
                )
        except (ValueError, TypeError):
            pass
    return await call_next(request)


async def background_gc():
    """Periodic garbage collection: temp files, GPU cache, expired jobs."""
    import gc

    while True:
        await asyncio.sleep(60)
        try:
            gc.collect()
        except Exception:
            pass

        try:
            import torch
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
        except Exception:
            pass

        cleanup_stale_temp_files(settings.TEMP_DIR, max_age_seconds=3600)

        # Expire old jobs (15 minutes after completion/failure)
        try:
            from backend.core.database import AsyncSessionLocal
            from backend.models.job import Job
            from sqlalchemy.future import select
            from datetime import datetime, timedelta

            async with AsyncSessionLocal() as db:
                fifteen_mins_ago = datetime.utcnow() - timedelta(minutes=15)
                stmt = select(Job).where(
                    Job.status.in_(["completed", "failed"]),
                    Job.updated_at < fifteen_mins_ago,
                )
                old_jobs = (await db.execute(stmt)).scalars().all()
                for job in old_jobs:
                    job.status = "expired"
                    job.result_json = {"message": "Job expired and data was pruned"}
                    db.add(job)
                if old_jobs:
                    await db.commit()
                    logger.info(f"GC: expired {len(old_jobs)} stale job(s)")
        except Exception as e:
            logger.warning(f"GC job expiration failed: {e}")


@app.on_event("startup")
async def startup_event():
    # ── Multi-worker Safety Guard ──────────────────────────────────────
    workers = max(
        int(os.environ.get("WEB_CONCURRENCY", 1)),
        int(os.environ.get("GUNICORN_WORKERS", 1)),
        int(os.environ.get("UVICORN_WORKERS", 1)),
    )
    if workers > 1:
        logger.error(f"FurSpeak backend started with {workers} workers.")
        raise RuntimeError("FurSpeak backend currently supports only ONE worker due to GPU serialization architecture. Set workers to 1.")

    # ── Move Heavy Initialization to Background ────────────────────────
    asyncio.create_task(initialize_backend())

async def initialize_backend():
    # ── Database Initialization (with retry for cold starts) ──────────
    import time
    for i in range(5):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("Database initialization successful.")
            break
        except Exception as e:
            if i == 4:
                logger.error(f"FATAL: Database initialization failed after 5 attempts: {e}")
                # We don't raise here to prevent crashing the whole process; 
                # health check will reflect the failure.
            else:
                logger.warning(f"Database connection attempt {i+1} failed. Retrying in 5s... ({e})")
                await asyncio.sleep(5)

    # ── Model Warmup (Resilient for slow environments) ────────────────
    try:
        import numpy as np
        logger.info("Running Model Warmup...")
        dummy = np.zeros((640, 640, 3), dtype=np.uint8)
        dog_det = model_loader.get_dog_detector()
        if dog_det:
            dog_det(dummy, conf=0.4, verbose=False)
        logger.info("Model warmup successful.")
    except Exception as e:
        logger.warning(f"Model warmup skipped or failed: {e}. The first request might be slow.")

    # ── Start GPU worker FIRST (H1 fix — must be running before recovery tasks enqueue) ──
    asyncio.create_task(gpu_worker())
    asyncio.create_task(background_gc())

    # ── Job Recovery (Crash Safety) — AFTER worker is running ──────────
    from sqlalchemy.future import select
    from backend.models.job import Job
    from backend.core.database import AsyncSessionLocal
    from backend.services.detection_service import DetectionService

    try:
        async with AsyncSessionLocal() as db:
            stmt = select(Job).where(Job.status == "processing")
            stuck_jobs = (await db.execute(stmt)).scalars().all()
            for job in stuck_jobs:
                if job.request_hash:
                    isolated_path = os.path.join(settings.TEMP_DIR, job.id, "video.mp4")
                    if os.path.exists(isolated_path):
                        logger.info(f"Re-queuing stuck job {job.id}")
                        from backend.models.user import User

                        mock_user = User(id=job.user_id or f"guest_recovered_{job.id}")
                        mock_user.is_guest = job.user_id is None
                        asyncio.create_task(
                            DetectionService._video_worker_task(
                                job.id, isolated_path, job.request_hash, mock_user
                            )
                        )
                    else:
                        logger.warning(f"Marking job {job.id} as failed (temp file missing)")
                        job.status = "failed"
                        job.result_json = {"error": "Server restarted and source file was lost."}
                        db.add(job)
            await db.commit()
    except Exception as e:
        logger.warning(f"Job recovery failed: {e}")

    dev = model_loader.get_device()
    logger.info(f"API Background Init Complete. Device: {dev}")


# ── C5 FIX: REMOVED StaticFiles(directory=TEMP_DIR) ──────────────────
# Temp directory must NEVER be publicly accessible.
# Thumbnails are served exclusively via Firebase Storage URLs.


@app.get("/ping")
async def ping():
    return {"status": "ok"}


@app.get("/health")
@app.get("/")
async def health_check():
    db_connected = False
    try:
        from backend.core.database import AsyncSessionLocal
        from sqlalchemy import text
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
            db_connected = True
    except Exception as e:
        logger.error(f"DB Healthcheck failed: {e}")

    # Check Temp Storage capacity (require at least 100MB free)
    temp_storage_ok = True
    try:
        import shutil
        total, used, free = shutil.disk_usage(settings.TEMP_DIR)
        if free < 100 * 1024 * 1024:
            temp_storage_ok = False
            logger.warning("Low temp storage space")
    except Exception:
        temp_storage_ok = False

    # Check Queue Depth
    queue_depth = 0
    try:
        from backend.core.worker import get_queue_size
        queue_depth = get_queue_size()
    except Exception:
        pass

    # Check Firebase
    firebase_initialized = False
    try:
        import firebase_admin
        if firebase_admin._apps:
            firebase_initialized = True
    except Exception:
        pass

    status_code = 200 if (db_connected and temp_storage_ok) else 503

    return JSONResponse(
        status_code=status_code,
        content={
            "database": "ok" if db_connected else "failed",
            "model_loaded": model_loader._initialized,
            "queue_depth": queue_depth,
            "temp_storage_ok": temp_storage_ok,
            "firebase_initialized": firebase_initialized
        }
    )


app.include_router(auth.router, prefix="/api/v1")
app.include_router(dog.router, prefix="/api/v1")
app.include_router(detection.router, prefix="/api/v1")
app.include_router(history.router, prefix="/api/v1")
