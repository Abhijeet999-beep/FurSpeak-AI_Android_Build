import os
import sys
from backend.core.config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Test")

def run_tests():
    try:
        logger.info(f"Config OK: ENVIRONMENT={settings.ENVIRONMENT}, TEMP_DIR={settings.TEMP_DIR}")
        from backend.main import app
        logger.info("Main app imported successfully!")
        
        from backend.services.detection_service import DetectionService
        logger.info("DetectionService imported successfully!")
        
        from backend.services.video_service import VideoService
        logger.info("VideoService imported successfully!")
        
        print("ALL IMPORTS OK")
    except Exception as e:
        logger.error(f"Import failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
