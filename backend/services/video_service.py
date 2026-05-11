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
            logger.info(f"[TIMING][{request_id}] Video Metadata: duration={duration:.2f}s, total_frames={total_frames}, fps={fps}")
            
            if duration > settings.MAX_VIDEO_DURATION_SECONDS + 2:
                raise FurSpeakException(
                    "VIDEO_TOO_LONG",
                    f"Video exceeds max duration of {settings.MAX_VIDEO_DURATION_SECONDS}s.",
                    400,
                )

            # PHASE 1: Aggressive frame sampling
            target_count_before = settings.MAX_FRAMES_TO_PROCESS
            target_count = int(duration)
            if target_count < 1:
                target_count = 1
            if target_count > 10:
                target_count = 10
            
            logger.info(f"[FRAME SAMPLING] video duration -> {duration:.2f}s, source fps -> {fps}, frames analyzed -> {target_count}")

            frame_step = max(1, total_frames // target_count) if target_count > 0 else total_frames

            classes = model_loader.get_classes()

            label_list = []
            timeline = []
            best_conf = -1
            best_frame = None
            valid_detections = []

            # Variables for tracking optimizations
            last_dog_roi_bbox = None
            consecutive_roi_reuses = 0
            dog_inference_time = 0.0
            emo_inference_time = 0.0

            t0_loop = time.perf_counter()
            frame_idx = 0
            frames_processed = 0

            # PHASE 2: Sequential reading to avoid cap.set()
            while True:
                ret = cap.grab()
                if not ret:
                    break

                if frame_idx % frame_step == 0 and frames_processed < target_count:
                    ret, frame = cap.retrieve()
                    if not ret:
                        break

                    gray_mean = cv2.mean(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY))[0]
                    if gray_mean < _BRIGHTNESS_SKIP_THRESHOLD:
                        frame_idx += 1
                        del frame
                        continue

                    try:
                        # PHASE 3: Downscale Before YOLO
                        h, w = frame.shape[:2]
                        max_dim = 640
                        if max(h, w) > max_dim:
                            scale = max_dim / max(h, w)
                            new_w, new_h = int(w * scale), int(h * scale)
                            frame = cv2.resize(frame, (new_w, new_h))
                            if frames_processed == 0:
                                logger.info(f"[PREPROCESS] original resolution -> {w}x{h}, resized resolution -> {new_w}x{new_h}")

                        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                        
                        # PHASE 4: ROI Tracking Shortcut
                        reused = False
                        if last_dog_roi_bbox and consecutive_roi_reuses < 2:
                            x1, y1, x2, y2 = last_dog_roi_bbox
                            roi_h, roi_w = rgb.shape[:2]
                            x1, y1 = max(0, x1), max(0, y1)
                            x2, y2 = min(roi_w, x2), min(roi_h, y2)
                            
                            if x2 > x1 and y2 > y1:
                                roi = rgb[y1:y2, x1:x2]
                                dog_conf = 0.99
                                bbox = (x1, y1, x2, y2)
                                consecutive_roi_reuses += 1
                                reused = True
                                logger.info(f"[OPTIMIZATION][{request_id}] Reused ROI from previous frame.")

                        if not reused:
                            t0_dog = time.perf_counter()
                            roi, bbox, dog_conf = InferenceService.detect_dog_and_roi(rgb, request_id, min_confidence=0.6)
                            t_dog = time.perf_counter() - t0_dog
                            dog_inference_time += t_dog
                            last_dog_roi_bbox = bbox
                            consecutive_roi_reuses = 0

                        valid_detections.append({"confidence": dog_conf, "bbox": bbox})

                        t0_emo = time.perf_counter()
                        emotion, conf, label_idx = InferenceService.predict_emotion(roi)
                        t_emo = time.perf_counter() - t0_emo
                        emo_inference_time += t_emo
                        
                        label_list.append(label_idx)

                        second = int((frame_idx / fps))
                        if len(timeline) == 0 or timeline[-1].emotion != emotion:
                            timeline.append(TimelineEntry(frame=second, emotion=emotion))

                        if conf > best_conf:
                            best_conf = conf
                            best_frame = frame.copy()

                        # PHASE 7: Early Exit Strategy
                        if len(timeline) >= 5:
                            recent_emotions = [entry.emotion for entry in timeline[-5:]]
                            if len(set(recent_emotions)) == 1:
                                logger.info(f"[{request_id}] EARLY EXIT: Dominant emotion '{emotion}' consistent.")
                                break

                    except FurSpeakException:
                        pass
                    finally:
                        del frame
                        if "rgb" in dir():
                            del rgb
                    
                    frames_processed += 1
                    if frames_processed >= target_count:
                        break

                frame_idx += 1

            loop_time = time.perf_counter() - t0_loop
            # PHASE 9: Benchmark Report
            logger.info(f"\n| Stage | Before | After |\n| --- | --- | --- |\n| Frame count | {target_count_before} | {target_count} |\n| Dog inference total | ~ | {dog_inference_time:.4f} s |\n| Emotion inference total | ~ | {emo_inference_time:.4f} s |\n| Total loop | ~ | {loop_time:.4f} s |")

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

        t0_save = time.perf_counter()
        cv2.imwrite(best_frame_path, best_frame)
        logger.info(f"[TIMING][{request_id}] cv2.imwrite best_frame: {time.perf_counter() - t0_save:.4f}s")
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
