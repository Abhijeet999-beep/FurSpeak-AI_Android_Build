import cv2
import os
import uuid
import time
import numpy as np
from collections import Counter
from backend.services.inference_service import InferenceService
from backend.services.caption_service import CaptionService
from backend.schemas.detection import DetectionResult, TimelineEntry
from backend.core.exceptions import FurSpeakException
from backend.core.config import settings
from backend.core.model_loader import model_loader
import logging

logger = logging.getLogger("FurSpeak-VideoService")
_BRIGHTNESS_SKIP_THRESHOLD = 15


class VideoService:
    @staticmethod
    def process_video(video_path: str, request_id: str = "unknown") -> tuple[DetectionResult, str]:
        """Returns (DetectionResult, best_frame_local_path)"""
        t0_total = time.perf_counter()

        cap = cv2.VideoCapture(video_path)
        try:
            if not cap.isOpened():
                raise FurSpeakException("INVALID_FILE", "Failed to open video file.", 400)

            fps = cap.get(cv2.CAP_PROP_FPS)
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            if fps == 0 or fps is None or np.isnan(fps):
                fps = 30.0

            duration = total_frames / fps
            if duration > settings.MAX_VIDEO_DURATION_SECONDS + 2:
                raise FurSpeakException(
                    "VIDEO_TOO_LONG",
                    f"Video exceeds max duration of {settings.MAX_VIDEO_DURATION_SECONDS}s.",
                    400,
                )

            target_count = settings.MAX_FRAMES_TO_PROCESS

            if target_count > 1 and duration > 0:
                sample_ms = [round(i * (duration * 1000) / (target_count - 1)) for i in range(target_count)]
            else:
                sample_ms = [0]

            classes = model_loader.get_classes()

            label_list = []
            timeline = []
            best_conf = -1
            best_frame = None
            valid_detections = []

            for ts_ms in sample_ms:
                cap.set(cv2.CAP_PROP_POS_MSEC, ts_ms)
                ret, frame = cap.read()
                if not ret:
                    continue

                gray_mean = cv2.mean(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY))[0]
                if gray_mean < _BRIGHTNESS_SKIP_THRESHOLD:
                    del frame
                    continue

                try:
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    roi, bbox, dog_conf = InferenceService.detect_dog_and_roi(rgb, request_id, min_confidence=0.6)
                    valid_detections.append({"confidence": dog_conf, "bbox": bbox})

                    emotion, conf, label_idx = InferenceService.predict_emotion(roi)
                    label_list.append(label_idx)

                    second = int(ts_ms / 1000)
                    if len(timeline) == 0 or timeline[-1].emotion != emotion:
                        timeline.append(TimelineEntry(frame=second, emotion=emotion))

                    if conf > best_conf:
                        best_conf = conf
                        best_frame = frame.copy()

                except FurSpeakException:
                    continue
                finally:
                    # Explicit cleanup to prevent memory buildup during frame loop
                    del frame
                    if "rgb" in dir():
                        del rgb

        finally:
            # H3 fix: ALWAYS release VideoCapture regardless of exception path
            cap.release()

        # Gate Logic
        valid_frames = len(valid_detections)
        avg_conf = sum(d["confidence"] for d in valid_detections) / valid_frames if valid_frames > 0 else 0

        if valid_frames < 3 and sum(1 for d in valid_detections if d["confidence"] >= 0.85) < 2:
            raise FurSpeakException("NOT_A_DOG", "Object did not pass validation.", 400)

        if not label_list or best_frame is None:
            raise FurSpeakException("NO_EMOTION_DETECTED", "No emotion detected.", 400)

        most_common_label = Counter(label_list).most_common(1)[0][0]
        final_emotion = classes[most_common_label]
        confidence = round(label_list.count(most_common_label) / len(label_list), 4)

        # M6 fix: Write best_frame to the same job-isolated directory as the video
        job_dir = os.path.dirname(video_path)
        if job_dir == settings.TEMP_DIR:
            # Fallback: if video is directly in TEMP_DIR, use flat path
            best_frame_filename = f"best_frame_{uuid.uuid4().hex}.jpg"
            best_frame_path = os.path.join(settings.TEMP_DIR, best_frame_filename)
        else:
            best_frame_path = os.path.join(job_dir, f"best_frame_{uuid.uuid4().hex}.jpg")

        cv2.imwrite(best_frame_path, best_frame)
        del best_frame  # Free memory immediately

        transitions = []
        prev = None
        for idx in label_list:
            if prev is not None and idx != prev:
                transitions.append((classes[prev], classes[idx]))
            prev = idx

        first = classes[label_list[0]]
        last = classes[label_list[-1]]

        caption, _ = CaptionService.get_summary_caption(final_emotion, transitions, first, last)
        suggestion = "Great time for a walk." if final_emotion.lower() == "happy" else "Give them a treat."

        if len(timeline) > settings.MAX_TIMELINE_LENGTH:
            step = len(timeline) / settings.MAX_TIMELINE_LENGTH
            timeline = [timeline[int(i * step)] for i in range(settings.MAX_TIMELINE_LENGTH)]

        elapsed = time.perf_counter() - t0_total
        logger.info(f"[{request_id}] Video processed in {elapsed:.2f}s — {final_emotion} ({confidence})")

        result = DetectionResult(
            emotion=final_emotion,
            confidence=confidence,
            caption=caption,
            suggestion=suggestion,
            thumbnail_url="",  # Set by DetectionService
            timeline=timeline,
        )
        return result, best_frame_path
