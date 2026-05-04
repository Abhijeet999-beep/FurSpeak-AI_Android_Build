import cv2
import os
import uuid
import time
import numpy as np
from collections import Counter
from datetime import datetime
from backend.services.inference_service import InferenceService
from backend.services.caption_service import CaptionService
from backend.schemas.response_models import EmotionResponse, TimelineEntry
from backend.core.exceptions import FurSpeakException
from backend.core.config import Config
from backend.core.model_loader import model_loader


# Darkness threshold for blank/black frame fast-fail.
# Frames with mean pixel brightness below this value are skipped entirely
# before even calling YOLO — avoids wasting GPU cycles on dark/blurry frames.
_BRIGHTNESS_SKIP_THRESHOLD = 15  # 0–255 scale; 15 ≈ near-black


class VideoService:
    @staticmethod
    def process_video(video_path: str, base_url: str, source_tag: str, request_id: str = "unknown", start_time: float = None) -> EmotionResponse:
        t0_total = time.perf_counter()

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise FurSpeakException("INVALID_FILE", "Failed to open video file.")

        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        if fps == 0 or fps is None or np.isnan(fps):
            fps = 30.0  # defensive fallback

        duration = total_frames / fps
        if duration > Config.MAX_VIDEO_DURATION_SECONDS:
            cap.release()
            raise FurSpeakException(
                "VIDEO_TOO_LONG",
                f"Video exceeds max duration of {Config.MAX_VIDEO_DURATION_SECONDS}s."
            )

        # ─── MULTI-FRAME VALIDATION GATE CONFIG ──────────────────────────────
        FRAME_SAMPLE_SIZE = 5
        MIN_VALID_FRAMES = 3
        MIN_CONFIDENCE = 0.6
        MIN_AVG_CONFIDENCE = 0.65
        HIGH_CONF_THRESHOLD = 0.85
        MIN_HIGH_CONF_FRAMES = 2
        MAX_POSITION_SHIFT_RATIO = 0.15

        target_count = FRAME_SAMPLE_SIZE

        # Evenly distribute sample timestamps (in milliseconds) across the video
        if target_count > 1 and duration > 0:
            sample_ms = [
                round(i * (duration * 1000) / (target_count - 1))
                for i in range(target_count)
            ]
        else:
            sample_ms = [0]

        classes = model_loader.get_classes()

        label_list = []
        timeline   = []
        best_conf  = -1
        best_frame = None
        skipped_black  = 0
        skipped_nodog  = 0
        
        valid_detections = []

        for ts_ms in sample_ms:
            seek_t = time.perf_counter()

            cap.set(cv2.CAP_PROP_POS_MSEC, ts_ms)
            ret, frame = cap.read()

            seek_ms = round((time.perf_counter() - seek_t) * 1000, 1)

            if not ret:
                continue

            gray_mean = cv2.mean(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY))[0]
            if gray_mean < _BRIGHTNESS_SKIP_THRESHOLD:
                skipped_black += 1
                print(f"⬛ [VIDEO] ts={ts_ms}ms brightness={gray_mean:.1f} → skipped (black frame)")
                continue

            try:
                infer_t = time.perf_counter()
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                
                roi, bbox, dog_conf = InferenceService.detect_dog_and_roi(rgb, request_id, start_time, min_confidence=MIN_CONFIDENCE)
                valid_detections.append({
                    "confidence": dog_conf,
                    "bbox": bbox
                })
                
                print(f"[TRACE {request_id}] ENTERING EMOTION MODEL")
                emotion, conf, label_idx = InferenceService.predict_emotion(roi)
                infer_ms = round((time.perf_counter() - infer_t) * 1000, 1)

                label_list.append(label_idx)

                second = int(ts_ms / 1000)
                if len(timeline) == 0 or timeline[-1].emotion != emotion:
                    timeline.append(TimelineEntry(frame=second, emotion=emotion))

                if conf > best_conf:
                    best_conf  = conf
                    best_frame = frame.copy()

                print(
                    f"✅ [VIDEO] ts={ts_ms}ms seek={seek_ms}ms "
                    f"infer={infer_ms}ms bright={gray_mean:.0f} "
                    f"→ {emotion} ({conf:.2f})"
                )

            except FurSpeakException:
                skipped_nodog += 1
                continue  # no dog detected in this frame — skip silently
            except Exception as e:
                print(f"⚠️ [VIDEO] ts={ts_ms}ms error: {e}")

        # compute video dimensions before release
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        cap.release()
        
        import math
        def get_center(bbox):
            x1, y1, x2, y2 = bbox
            return ((x1 + x2)/2, (y1 + y2)/2)

        def distance(c1, c2):
            return math.sqrt((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2)

        diag = math.sqrt(width**2 + height**2)
        max_shift = diag * MAX_POSITION_SHIFT_RATIO

        # Gate Logic
        valid_frames = len(valid_detections)
        avg_conf = sum(d['confidence'] for d in valid_detections) / valid_frames if valid_frames > 0 else 0
        high_conf_frames = sum(1 for d in valid_detections if d['confidence'] >= HIGH_CONF_THRESHOLD)
        
        consistent_frames = 0
        for i in range(1, len(valid_detections)):
            c1 = get_center(valid_detections[i-1]['bbox'])
            c2 = get_center(valid_detections[i]['bbox'])
            if distance(c1, c2) < max_shift:
                consistent_frames += 1

        if (valid_frames >= MIN_VALID_FRAMES and 
            avg_conf >= MIN_AVG_CONFIDENCE and 
            consistent_frames >= 2):
            decision = "PASS"
        elif high_conf_frames >= MIN_HIGH_CONF_FRAMES:
            decision = "PASS (OVERRIDE)"
        else:
            decision = "REJECT"

        print(f"[TRACE {request_id}] VALID FRAMES → {valid_frames}")
        print(f"[TRACE {request_id}] AVG CONF → {avg_conf:.2f}")
        print(f"[TRACE {request_id}] HIGH CONF FRAMES → {high_conf_frames}")
        print(f"[TRACE {request_id}] CONSISTENT FRAMES → {consistent_frames}")
        print(f"[TRACE {request_id}] FINAL DECISION → {decision}")

        total_ms = round((time.perf_counter() - t0_total) * 1000)
        print(
            f"📊 [VIDEO] Done — sampled={len(sample_ms)} "
            f"detected={len(label_list)} skipped_black={skipped_black} "
            f"skipped_nodog={skipped_nodog} total={total_ms}ms"
        )
        
        if decision == "REJECT":
            raise FurSpeakException("NOT_A_DOG", "Object did not pass multi-frame dog validation.")

        if not label_list or best_frame is None:
            raise FurSpeakException(
                "NO_EMOTION_DETECTED",
                "No emotion detected across sampled frames."
            )

        most_common_label = Counter(label_list).most_common(1)[0][0]
        final_emotion     = classes[most_common_label]
        confidence        = round((label_list.count(most_common_label) / len(label_list)) * 100, 2)

        # Save best frame to static dir
        best_frame_filename = f"best_frame_{uuid.uuid4().hex}.jpg"
        best_frame_path     = os.path.join(Config.TEMP_DIR, best_frame_filename)
        cv2.imwrite(best_frame_path, best_frame)

        frame_image_url = f"{base_url}/static/{best_frame_filename}" if base_url else None

        # Build emotion transition summary
        transitions = []
        prev = None
        for idx in label_list:
            if prev is not None and idx != prev:
                transitions.append((classes[prev], classes[idx]))
            prev = idx

        first = classes[label_list[0]]
        last  = classes[label_list[-1]]

        caption, timeline_summary = CaptionService.get_summary_caption(
            final_emotion, transitions, first, last
        )

        # Guard response payload size
        if len(timeline) > Config.MAX_TIMELINE_LENGTH:
            step     = len(timeline) / Config.MAX_TIMELINE_LENGTH
            timeline = [timeline[int(i * step)] for i in range(Config.MAX_TIMELINE_LENGTH)]

        return EmotionResponse(
            emotion=final_emotion,
            confidence=confidence,
            caption=caption,
            timeline=timeline,
            timeline_summary=timeline_summary,
            frame_sampled=len(label_list),
            processing_time=round(total_ms / 1000, 2),
            timestamp=datetime.utcnow().isoformat(),
            frame_image_path=best_frame_path,
            frame_image_url=frame_image_url,
            model_version=Config.MODEL_VERSION,
            request_source=source_tag
        )
