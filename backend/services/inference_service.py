from backend.core.model_loader import model_loader
from backend.core.exceptions import FurSpeakException
import numpy as np
import logging

logger = logging.getLogger("FurSpeak-InferenceService")


class InferenceService:
    @staticmethod
    def detect_dog_and_roi(rgb_image, request_id="unknown", start_time=None, min_confidence=0.6):
        import time

        dog_detector = model_loader.get_dog_detector()

        results = dog_detector(rgb_image, conf=0.4, verbose=False)

        detections = []
        if results and results[0].boxes:
            boxes = results[0].boxes
            for i in range(len(boxes.cls)):
                label_id = int(boxes.cls[i].item())
                label = results[0].names[label_id]
                conf = float(boxes.conf[i].item())
                bbox = boxes.xyxy[i].tolist()
                detections.append({
                    "label": label,
                    "confidence": round(conf, 4),
                    "bbox": [round(c, 2) for c in bbox],
                })
            
        logger.info(f"[INFERENCE][{request_id}] Raw Detections: {detections}")

        # H4 fix: replaced print() with logger
        logger.debug(f"[{request_id}] DETECTIONS → {detections}")
        logger.debug(f"[{request_id}] RAW LABELS → {[d['label'] for d in detections]}")

        # Filter for dogs with confidence threshold
        dogs = [d for d in detections if d["label"] == "dog" and d["confidence"] >= min_confidence]
        
        logger.info(f"[INFERENCE][{request_id}] Dog Filtered: {dogs}")
        
        if len(dogs) == 0:
            logger.info(f"[{request_id}] ❌ NO DOG DETECTED — BLOCKED")
            raise FurSpeakException("NO_DOG_DETECTED", "No dog detected in the frame.")
        else:
            logger.debug(f"[{request_id}] ✅ DOG DETECTED — PASSING TO EMOTION")

        if start_time:
            logger.debug(f"[{request_id}] DETECTION TIME → {time.time() - start_time}s")

        # ROI validation using the first detected dog
        first_dog = dogs[0]
        dog_conf = first_dog["confidence"]
        x1, y1, x2, y2 = map(int, first_dog["bbox"])

        h, w, _ = rgb_image.shape
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(w, x2), min(h, y2)

        if x2 <= x1 or y2 <= y1:
            raise FurSpeakException("INVALID_ROI", "Invalid bounding box dimensions after scaling.")

        roi = rgb_image[y1:y2, x1:x2]
        return roi, (x1, y1, x2, y2), dog_conf

    @staticmethod
    def predict_emotion(roi):
        behavior_model = model_loader.get_behavior_model()
        classes = model_loader.get_classes()

        result = behavior_model(roi, verbose=False)
        boxes = result[0].boxes

        if not boxes or boxes.cls is None or len(boxes.cls) == 0:
            raise FurSpeakException("NO_EMOTION_DETECTED", "No emotion detected from ROI.")

        confidences = boxes.conf.cpu().numpy()
        labels = boxes.cls.cpu().numpy().astype(int)

        top_indices = np.argsort(confidences)[::-1]
        best_label_idx = labels[top_indices[0]]
        best_conf = float(confidences[top_indices[0]])

        logger.info(f"[INFERENCE] Raw Emotion Confidences: {confidences.tolist()}")
        logger.info(f"[INFERENCE] Top Emotion: {classes[best_label_idx] if best_label_idx < len(classes) else 'UNKNOWN'} (conf: {best_conf})")

        if best_label_idx < len(classes):
            return classes[best_label_idx], best_conf, int(best_label_idx)
        
        # Graceful fallback for model mismatch (e.g. using base YOLO model instead of trained behavior model)
        model_names = result[0].names
        actual_name = model_names.get(best_label_idx, f"id_{best_label_idx}")
        logger.warning(f"Inference mismatch: best_label_idx {best_label_idx} ({actual_name}) out of bounds for EMOTION_CLASSES. Returning '{classes[0]}'.")
        return classes[0], best_conf, 0
