from fastapi import FastAPI, File, UploadFile, Request, APIRouter, Depends
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from backend.core.config import Config
from backend.core.model_loader import model_loader
from backend.core.exceptions import FurSpeakException, furspeak_exception_handler
from backend.core.security import verify_firebase_token
from backend.core.rate_limiter import api_limiter
from backend.core.cache import InMemoryResponseCache, compute_sha256
from backend.core.worker import job_queue, gpu_worker
from backend.utils.media_validator import validate_magic_bytes
from backend.services.image_service import ImageService
from backend.services.video_service import VideoService
import os
import time
import uuid
import asyncio
import logging
import shutil
import tempfile

app = FastAPI(title="FurSpeak AI")

def _safe_remove(path: str):
    """Remove a temp file if it exists, swallowing errors (e.g., file already deleted or locked)."""
    try:
        if os.path.exists(path):
            os.remove(path)
    except OSError:
        pass

def _cleanup_stale_temp_files(max_age_seconds: int = 3600):
    """Remove temp files older than max_age_seconds from TEMP_DIR."""
    try:
        now = time.time()
        for filename in os.listdir(Config.TEMP_DIR):
            filepath = os.path.join(Config.TEMP_DIR, filename)
            if os.path.isfile(filepath):
                age = now - os.path.getmtime(filepath)
                if age > max_age_seconds:
                    _safe_remove(filepath)
    except Exception:
        pass  # Non-critical — don't crash the GC loop

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("FurSpeak-API")

app.add_exception_handler(FurSpeakException, furspeak_exception_handler)

response_cache = InMemoryResponseCache(max_size=200)

@app.on_event("startup")
async def startup_event():
    # Start GPU background worker
    asyncio.create_task(gpu_worker())
    
    # Start background GC loop resolving Request-Level Thread-Blocks
    asyncio.create_task(background_gc())
    
    dev = model_loader.get_device()
    logger.info(f"API Started. Device: {dev}")

async def background_gc():
    """ Background Periodic Memory Cleaning + Temp File Cleanup. """
    import gc
    import torch
    while True:
        await asyncio.sleep(60)  # Run every minute
        gc.collect()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        # Clean up temp files older than 1 hour (best_frame images, compressed uploads, etc.)
        _cleanup_stale_temp_files(max_age_seconds=3600)

app.mount("/static", StaticFiles(directory=Config.TEMP_DIR), name="static")

@app.get("/")
def health_check():
    return {"status": "running", "message": "FurSpeak AI Backend is online"}

api_v1_router = APIRouter(prefix="/api/v1")

@api_v1_router.post("/predict")
async def predict(
    request: Request, 
    file: UploadFile = File(...), 
    uid: str = Depends(verify_firebase_token)
):
    source_tag = request.headers.get("x-source", "unknown")
    print(f"🔥🔥🔥 /predict HIT | uid={uid} | file={file.filename} | source={source_tag} | size={file.size}")
    logger.info(f"🔥 /predict HIT | uid={uid} | file={file.filename} | source={source_tag}")
    
    # Rate Limit Check explicitly bounding user traffic DDos
    api_limiter.check_rate_limit(uid)
    
    request_id = uuid.uuid4().hex
    start_time = time.time()
    
    print(f"[TRACE {request_id}] REQUEST RECEIVED")
    
    # We shouldn't load file into memory entirely. Stream to disk safely.
    fd, temp_path = tempfile.mkstemp(dir=Config.TEMP_DIR, suffix=os.path.splitext(file.filename)[-1].lower())
    os.close(fd) 
    
    try:
        # Stream file safely protecting RAM
        with open(temp_path, "wb") as f_out:
            shutil.copyfileobj(file.file, f_out)
        
        file_size = os.path.getsize(temp_path)
        mime_type = file.content_type
        print(f"[TRACE {request_id}] FILE SIZE: {file_size}")
        print(f"[TRACE {request_id}] FILE TYPE: {mime_type}")
        
        if file_size > Config.MAX_FILE_SIZE_BYTES:
            raise FurSpeakException("FILE_TOO_LARGE", f"File exceeds max size of {Config.MAX_FILE_SIZE_BYTES//(1024*1024)}MB", 413)

        # Magic Bytes Validation eliminating file spoofing
        if not validate_magic_bytes(temp_path):
            raise FurSpeakException("CORRUPT_MEDIA", "File verification failed. Unsupported encoding.", 400)

        # Cache Hash Computation 
        file_ext = os.path.splitext(file.filename)[-1].lower()
        file_hash = compute_sha256(temp_path)
        
        cached_response = response_cache.get(file_hash)
        if cached_response:
            logger.info(f"[REQ:{request_id}] CACHE HIT. Returning instantly.")
            return cached_response

        # *** PHASE 10: CACHE STAMPEDE PROTECTION ***
        flight_event = response_cache.get_flight_event(file_hash)
        if flight_event:
            logger.info(f"[REQ:{request_id}] STAMPEDE INTERCEPTED. Waiting for in-flight job...")
            try:
                await asyncio.wait_for(flight_event.wait(), timeout=Config.REQUEST_TIMEOUT_SECONDS)
                resolved_cache = response_cache.get(file_hash)
                if resolved_cache:
                    proc_time = round(time.time() - start_time, 2)
                    logger.info(f"[REQ:{request_id}] STAMPEDE HIT | time: {proc_time}s")
                    return resolved_cache
            except asyncio.TimeoutError:
                logger.error(f"[REQ:{request_id}] TIMEOUT_ERROR while awaiting stampede lock.")
                return JSONResponse(status_code=504, content={"error_type": "TIMEOUT", "message": "Processing took too long."})

        # Lock the file explicitly
        response_cache.start_flight(file_hash)

        loop = asyncio.get_running_loop()
        future = loop.create_future()
        
        # Enqueue the workload isolated to the single background worker sequentially
        if file_ext in [".jpg", ".jpeg", ".png"]:
            await job_queue.put((request_id, future, ImageService.process_image, (temp_path, source_tag, request_id, start_time), {}))
        elif file_ext in [".mp4", ".mov", ".avi"]:
            base_url = str(request.base_url).rstrip('/')
            await job_queue.put((request_id, future, VideoService.process_video, (temp_path, base_url, source_tag, request_id, start_time), {}))
        else:
            response_cache.resolve_flight(file_hash)
            raise FurSpeakException("UNSUPPORTED_MEDIA", "File extension mapped incorrectly natively.", 400)
            
        try:
            result = await asyncio.wait_for(future, timeout=Config.REQUEST_TIMEOUT_SECONDS)
            result.processing_time = round(time.time() - start_time, 2)
            final_dict = result.model_dump()
            
            # 3600 ttl cache
            response_cache.set(file_hash, final_dict, 3600)
            response_cache.resolve_flight(file_hash)

            logger.info(f"[REQ:{request_id}] FINAL RESPONSE → {final_dict}")
            
            proc_time = round(time.time() - start_time, 2)
            logger.info(f"[REQ:{request_id}] SUCCESS | UID: {uid} | time: {proc_time}s")

            # Cleanup temp file AFTER worker has finished processing
            _safe_remove(temp_path)

            return final_dict

        except asyncio.TimeoutError:
            response_cache.resolve_flight(file_hash)
            future.cancel()
            logger.error(f"[REQ:{request_id}] TIMEOUT_ERROR | Exceeded {Config.REQUEST_TIMEOUT_SECONDS}s")
            # Schedule deferred cleanup — worker may still be reading the file
            asyncio.get_running_loop().call_later(Config.REQUEST_TIMEOUT_SECONDS, _safe_remove, temp_path)
            return JSONResponse(status_code=504, content={"error_type": "TIMEOUT", "message": "Processing took too long. Try a shorter video."})

    except FurSpeakException as fse:
        try: response_cache.resolve_flight(file_hash) 
        except: pass
        _safe_remove(temp_path)
        logger.warning(f"[REQ:{request_id}] FURSPEAK_EXCEPTION | {fse.error_type}: {fse.message}")
        raise fse
    except Exception as e:
        try: response_cache.resolve_flight(file_hash) 
        except: pass
        _safe_remove(temp_path)
        import traceback
        error_msg = str(e)
        logger.error(f"❌ ERROR IN PREDICT ENDPOINT: {error_msg}")
        logger.error(traceback.format_exc())
        return JSONResponse(status_code=500, content={"error": "Backend processing failed", "details": error_msg})

app.include_router(api_v1_router)
