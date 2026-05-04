import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class Config:
    DEBUG_VISUAL = os.getenv("DEBUG_VISUAL", "False").lower() in ("true", "1", "t")
    TEMP_DIR = os.path.join(BASE_DIR, os.getenv("TEMP_DIR", "temp"))
    
    # YOLO Model paths
    DOG_DETECTOR_MODEL_PATH = os.path.join(BASE_DIR, "models", "yolov8m.pt")
    BEHAVIOR_MODEL_PATH = os.path.join(BASE_DIR, "models", "best.pt")

    MAX_VIDEO_DURATION_SECONDS = int(os.getenv("MAX_VIDEO_DURATION_SECONDS", 60))
    MAX_FRAMES_TO_PROCESS = int(os.getenv("MAX_FRAMES_TO_PROCESS", 60))
    MAX_TIMELINE_LENGTH = int(os.getenv("MAX_TIMELINE_LENGTH", 30)) # Limit payload bloat

    # Concurrency & Limits
    MAX_CONCURRENT_REQUESTS = int(os.getenv("MAX_CONCURRENT_REQUESTS", 2))
    REQUEST_TIMEOUT_SECONDS = int(os.getenv("REQUEST_TIMEOUT_SECONDS", 120))
    MAX_FILE_SIZE_BYTES = int(os.getenv("MAX_FILE_SIZE_BYTES", 50 * 1024 * 1024)) # 50 MB
    
    # Telemetry
    MODEL_VERSION = os.getenv("MODEL_VERSION", "yolov8m-v1-behavior-beta")

# Ensure base directories exist
os.makedirs(Config.TEMP_DIR, exist_ok=True)
