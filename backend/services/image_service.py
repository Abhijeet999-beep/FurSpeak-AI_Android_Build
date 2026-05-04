import cv2
from datetime import datetime
from backend.services.inference_service import InferenceService
from backend.services.caption_service import CaptionService
from backend.schemas.response_models import EmotionResponse
from backend.core.exceptions import FurSpeakException
from backend.core.config import Config
import uuid
import os

class ImageService:
    @staticmethod
    def process_image(image_path: str, source_tag: str, request_id: str = "unknown", start_time: float = None) -> EmotionResponse:
        img = cv2.imread(image_path)
        if img is None:
            raise FurSpeakException("INVALID_FILE", "Invalid image path or cannot read image.")
            
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        # Will raise NO_DOG_DETECTED or INVALID_ROI if failed
        roi, (x1, y1, x2, y2), dog_conf = InferenceService.detect_dog_and_roi(rgb, request_id, start_time, min_confidence=0.6)
        
        # 6. Static Image Logic
        if dog_conf < 0.65:
            print(f"[TRACE {request_id}] ❌ IMAGE DOG CONFIDENCE {dog_conf} < 0.65 — REJECT")
            raise FurSpeakException("NOT_A_DOG", f"Static image dog confidence {dog_conf} is below 0.65 threshold.")
        else:
            print(f"[TRACE {request_id}] ✅ IMAGE DOG CONFIDENCE {dog_conf} >= 0.65 — PASS")
        
        # Will raise NO_EMOTION_DETECTED if failed
        print(f"[TRACE {request_id}] ENTERING EMOTION MODEL")
        emotion, confidence, _ = InferenceService.predict_emotion(roi)
        
        # statistical confidence normalized to %
        confidence = round(confidence * 100, 2)
        
        caption = CaptionService.get_caption_for_emotion(emotion)
        
        return EmotionResponse(
            emotion=emotion,
            confidence=confidence,
            caption=caption,
            processing_time=0.0,
            timestamp=datetime.utcnow().isoformat(),
            imagePath=image_path,
            model_version=Config.MODEL_VERSION,
            request_source=source_tag
        )
