"""
Shared temporary file cleanup utilities.
Extracted from main.py to eliminate circular imports (C4).
"""
import os
import time
import shutil
import logging

logger = logging.getLogger("FurSpeak-TempCleanup")


def safe_remove(path: str):
    """Safely remove a single file, ignoring errors."""
    try:
        if path and os.path.exists(path):
            os.remove(path)
    except OSError as e:
        logger.debug(f"Failed to remove {path}: {e}")


def safe_rmdir(path: str):
    """Safely remove an empty directory, ignoring errors."""
    try:
        if path and os.path.isdir(path):
            os.rmdir(path)
    except OSError:
        pass


def cleanup_stale_temp_files(temp_dir: str, max_age_seconds: int = 3600):
    """
    Remove files older than max_age_seconds from the temp directory.
    Also removes empty subdirectories.
    """
    try:
        now = time.time()
        for entry in os.listdir(temp_dir):
            filepath = os.path.join(temp_dir, entry)
            if os.path.isfile(filepath):
                age = now - os.path.getmtime(filepath)
                if age > max_age_seconds:
                    safe_remove(filepath)
                    logger.debug(f"Cleaned stale temp file: {entry} (age={age:.0f}s)")
            elif os.path.isdir(filepath):
                # Clean stale job directories recursively
                dir_age = now - os.path.getmtime(filepath)
                if dir_age > max_age_seconds:
                    try:
                        shutil.rmtree(filepath)
                        logger.debug(f"Cleaned stale temp dir: {entry} (age={dir_age:.0f}s)")
                    except OSError as e:
                        logger.debug(f"Failed to clean temp dir {entry}: {e}")
                elif not os.listdir(filepath):
                    safe_rmdir(filepath)
    except Exception as e:
        logger.warning(f"Temp cleanup sweep failed: {e}")
