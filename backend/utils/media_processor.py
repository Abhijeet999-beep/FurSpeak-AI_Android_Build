import os
import subprocess
import json
from backend.core.exceptions import FurSpeakException
from backend.core.config import settings
from backend.utils.temp_cleanup import safe_remove
import logging

logger = logging.getLogger("FurSpeak-MediaProcessor")

# Timeout for FFmpeg operations to prevent hangs
_FFMPEG_TIMEOUT_SECONDS = 60


class MediaProcessor:
    @staticmethod
    def get_video_info(file_path: str) -> dict:
        """Runs ffprobe to extract duration, resolution, etc."""
        try:
            cmd = [
                "ffprobe", "-v", "quiet", "-print_format", "json",
                "-show_format", "-show_streams", file_path,
            ]
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
                timeout=_FFMPEG_TIMEOUT_SECONDS,
            )
            data = json.loads(result.stdout)

            duration = float(data.get("format", {}).get("duration", 0))

            # Find video stream
            video_stream = next(
                (s for s in data.get("streams", []) if s.get("codec_type") == "video"),
                None,
            )
            width = int(video_stream.get("width", 0)) if video_stream else 0
            height = int(video_stream.get("height", 0)) if video_stream else 0

            return {"duration": duration, "width": width, "height": height}
        except subprocess.TimeoutExpired:
            logger.error(f"ffprobe timed out after {_FFMPEG_TIMEOUT_SECONDS}s")
            raise FurSpeakException("PROBE_FAILED", "Video analysis timed out.", 400)
        except FileNotFoundError:
            logger.warning("ffprobe not found — skipping video validation")
            raise
        except Exception as e:
            logger.error(f"Failed to probe video info: {e}")
            raise FurSpeakException("PROBE_FAILED", "Could not analyze the video file.", 400)

    @staticmethod
    def apply_light_compression(input_path: str, output_path: str) -> bool:
        """Applies light compression to bring video down to 720p / 1.5Mbps."""
        try:
            max_h = settings.MAX_RESOLUTION_HEIGHT
            cmd = [
                "ffmpeg", "-y", "-i", input_path,
                "-vf", f"scale=-2:'min({max_h},ih)'",
                "-c:v", "libx264",
                "-b:v", "1500k",
                "-preset", "fast",
                "-c:a", "aac",
                "-b:a", "128k",
                output_path,
            ]
            subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
                timeout=_FFMPEG_TIMEOUT_SECONDS,
            )
            return True
        except subprocess.TimeoutExpired:
            logger.error(f"ffmpeg compression timed out after {_FFMPEG_TIMEOUT_SECONDS}s")
            safe_remove(output_path)
            return False
        except subprocess.CalledProcessError as e:
            logger.error(f"Compression failed: {e.stderr.decode() if e.stderr else 'unknown'}")
            safe_remove(output_path)
            return False
        except FileNotFoundError:
            logger.warning("ffmpeg not found — skipping compression")
            return False

    @staticmethod
    def validate_and_normalize_video(file_path: str) -> str:
        """
        Validates the video limits strictly. If it slightly breaches size or resolution,
        attempts compression. Returns the path to the validated (and possibly compressed) file.
        Throws FurSpeakException if strictly rejected.
        
        If ffprobe/ffmpeg is not available, returns the file as-is (graceful degradation).
        """
        file_size = os.path.getsize(file_path)

        # 1. Very heavy file rejection (over 2x limit is instant rejection)
        if file_size > settings.MAX_FILE_SIZE_BYTES * 2:
            raise FurSpeakException(
                "INVALID_VIDEO_INPUT",
                "Please trim and compress your video before uploading.",
                400,
            )

        # 2. Try ffprobe validation (graceful if ffmpeg not installed)
        try:
            info = MediaProcessor.get_video_info(file_path)
        except FileNotFoundError:
            logger.info("ffprobe not available — skipping video validation, passing through as-is")
            return file_path

        # 3. Strict duration rejection
        if info["duration"] > settings.MAX_VIDEO_DURATION_SECONDS + 2:  # 2s buffer
            raise FurSpeakException(
                "INVALID_VIDEO_INPUT",
                f"Please trim your video to under {settings.MAX_VIDEO_DURATION_SECONDS} seconds.",
                400,
            )

        # 4. Check if compression is needed
        needs_compression = False
        if file_size > settings.MAX_FILE_SIZE_BYTES:
            needs_compression = True
        if info["height"] > settings.MAX_RESOLUTION_HEIGHT and info["width"] > settings.MAX_RESOLUTION_HEIGHT:
            needs_compression = True

        if needs_compression:
            logger.info("Applying light compression as fallback.")
            compressed_path = f"{file_path}_compressed.mp4"
            success = MediaProcessor.apply_light_compression(file_path, compressed_path)
            if not success:
                # Graceful fallback: if compression fails, try with original
                logger.warning("Compression failed — proceeding with original file")
                return file_path

            # Check if compressed file fits limits
            if os.path.getsize(compressed_path) > settings.MAX_FILE_SIZE_BYTES:
                safe_remove(compressed_path)
                raise FurSpeakException(
                    "INVALID_VIDEO_INPUT",
                    "Video remains too large even after optimization.",
                    400,
                )

            # Remove original and return new path
            safe_remove(file_path)
            return compressed_path

        return file_path
