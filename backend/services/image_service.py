import cv2
import uuid
from backend.services.inference_service import InferenceService
from backend.services.caption_service import CaptionService
from backend.schemas.detection import DetectionResult
from backend.core.exceptions import FurSpeakException
import logging

logger = logging.getLogger("FurSpeak-ImageService")

class ImageService:
    @staticmethod
    def process_image(image_path: str, request_id: str = "unknown") -> DetectionResult:
        img = cv2.imread(image_path)
        if img is None:
            raise FurSpeakException("INVALID_FILE", "Invalid image path or cannot read image.", 400)
            
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Will raise NO_DOG_DETECTED or INVALID_ROI if failed
        roi, (x1, y1, x2, y2), dog_conf = InferenceService.detect_dog_and_roi(rgb, request_id, min_confidence=0.6)
        
        if dog_conf < 0.65:
            logger.info(f"[{request_id}] ❌ IMAGE DOG CONFIDENCE {dog_conf} < 0.65 — REJECT")
            raise FurSpeakException("NOT_A_DOG", "Object did not pass validation.", 400)
        
        # Will raise NO_EMOTION_DETECTED if failed
        emotion, confidence, _ = InferenceService.predict_emotion(roi)
        confidence = round(confidence, 4)
        
        caption = CaptionService.get_caption_for_emotion(emotion)
        # Adding a basic generic suggestion based on emotion
        suggestion = "Maybe it's a good time to play!" if emotion.lower() == "happy" else "Give them some space."
        
        return DetectionResult(
            emotion=emotion,
            confidence=confidence,
            caption=caption,
            suggestion=suggestion,
            thumbnail_url="", # Filled by DetectionService
            timeline=[]
        )
