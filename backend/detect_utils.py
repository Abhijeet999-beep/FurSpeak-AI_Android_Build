import cv2
import numpy as np
from collections import Counter
from ultralytics import YOLO
import uuid
import os
from datetime import datetime
import torch

# Load YOLO models
dog_detector = YOLO("backend/models/yolov8m.pt")
behavior_model = YOLO("backend/models/best.pt")

# Configuration
behavior_classes = ['relax', 'happy', 'angry', 'frown', 'alert']
CONF_THRESHOLD = 0.5
DEBUG_VISUAL = False
TEMP_DIR = "temp"
os.makedirs(TEMP_DIR, exist_ok=True)

# Draw bounding box for visualization (optional)
def draw_bbox(image, x1, y1, x2, y2, label):
    cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
    cv2.putText(image, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
    return image

# Emotion prediction from image
def detect_emotion_from_image(image_path):
    try:
        img = cv2.imread(image_path)
        if img is None:
            return error_response("Invalid image path or cannot read image.")

        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        dogs = dog_detector(rgb, classes=[16], conf=0.4)

        if not dogs or not dogs[0].boxes or len(dogs[0].boxes.xyxy) == 0:
            return error_response("No dog detected.")

        x1, y1, x2, y2 = map(int, dogs[0].boxes.xyxy[0])
        roi = rgb[y1:y2, x1:x2]
        behavior_result = behavior_model(roi)
        boxes = behavior_result[0].boxes

        if not boxes or boxes.cls is None or len(boxes.cls) == 0:
            return error_response("No emotion detected from ROI.")

        confidences = boxes.conf.cpu().numpy()
        labels = boxes.cls.cpu().numpy().astype(int)

        top_indices = np.argsort(confidences)[::-1][:3]
        top_predictions = [
            {"emotion": behavior_classes[labels[i]], "confidence": round(float(confidences[i]) * 100, 2)}
            for i in top_indices
        ]

        if DEBUG_VISUAL:
            debug_img = draw_bbox(img.copy(), x1, y1, x2, y2, top_predictions[0]['emotion'])
            debug_filename = os.path.join(TEMP_DIR, f"debug_{uuid.uuid4().hex}.jpg")
            cv2.imwrite(debug_filename, debug_img)

        # Compose response matching EmotionResponse model
        emotion = top_predictions[0]["emotion"]
        confidence = top_predictions[0]["confidence"]
        # Generate a friendly caption based on emotion
        captions = {
            'relax': "Your dog looks relaxed and content!",
            'happy': "Your dog is happy and playful!",
            'angry': "Your dog seems a bit upset. Give them some space.",
            'frown': "Your dog looks a little sad. Maybe some cuddles?",
            'alert': "Your dog is alert and attentive!"
        }
        caption = captions.get(emotion, "Your dog's mood is detected!")
        return {
            "imagePath": image_path,
            "emotion": emotion,
            "confidence": confidence,
            "caption": caption,
            "processing_time": 0.0,  # Optionally measure actual time
            "timestamp": datetime.utcnow().isoformat(),
            "video_info": None
        }

    except Exception as e:
        print(f"⚠️ Error during image emotion detection: {e}")
        return error_response(f"Could not process behavior from image. {str(e)}")

# Emotion detection from video
def detect_emotion_from_video(video_path, base_url=None):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return error_response("Failed to open video file.")

    label_list = []
    timeline = []
    frame_counter = 0
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    frame_interval = int(fps)  # 1 frame per second
    best_conf = -1
    best_frame = None
    best_frame_path = None
    best_emotion = None

    # Try CUDA first, fallback to CPU if needed
    try:
        if torch.cuda.is_available():
            device = torch.device('cuda')
            dog_detector.to(device)
            behavior_model.to(device)
        else:
            device = torch.device('cpu')
            dog_detector.to(device)
            behavior_model.to(device)
    except Exception as e:
        print(f"⚠️ Error setting up device: {e}")
        device = torch.device('cpu')
        dog_detector.to(device)
        behavior_model.to(device)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame_counter += 1
        if frame_counter % frame_interval != 0:
            continue

        try:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            dogs = dog_detector(rgb, classes=[16], conf=0.4)

            if not dogs or not dogs[0].boxes or len(dogs[0].boxes.xyxy) == 0:
                continue

            x1, y1, x2, y2 = map(int, dogs[0].boxes.xyxy[0])
            roi = rgb[y1:y2, x1:x2]
            behavior_result = behavior_model(roi)
            boxes = behavior_result[0].boxes

            if not boxes or boxes.cls is None or len(boxes.cls) == 0:
                continue

            label_idx = int(boxes.cls[0])
            conf = float(boxes.conf[0])
            label_list.append(label_idx)

            timeline.append({
                "frame": frame_counter,
                "emotion": behavior_classes[label_idx]
            })

            if conf > best_conf:
                best_conf = conf
                best_frame = frame.copy()
                best_emotion = behavior_classes[label_idx]
        except Exception as e:
            print(f"❌ Error processing frame {frame_counter}: {e}")
            # If CUDA error, try switching to CPU
            if "CUDA" in str(e):
                try:
                    print("⚠️ Switching to CPU for processing...")
                    device = torch.device('cpu')
                    dog_detector.to(device)
                    behavior_model.to(device)
                    continue  # Retry this frame with CPU
                except Exception as cpu_error:
                    print(f"❌ CPU fallback also failed: {cpu_error}")
            continue

    cap.release()

    if not label_list or best_frame is None:
        return error_response("No emotion detected. Ensure the dog is visible in the video.")

    most_common_label = Counter(label_list).most_common(1)[0][0]
    final_emotion = behavior_classes[most_common_label]
    confidence = round((label_list.count(most_common_label) / len(label_list)) * 100, 2)

    # Save best frame as image
    frame_image_path = None
    frame_image_url = None
    try:
        frame_filename = f"best_frame_{uuid.uuid4().hex}.jpg"
        frame_image_path = os.path.join(TEMP_DIR, frame_filename)
        cv2.imwrite(frame_image_path, cv2.cvtColor(best_frame, cv2.COLOR_RGB2BGR))
        if base_url:
            frame_image_url = f"{base_url}/static/{frame_filename}"
    except Exception as e:
        print(f"Error saving best frame: {e}")
        frame_image_path = None
        frame_image_url = None

    # Analyze transitions
    transitions = []
    prev = None
    for idx in label_list:
        if prev is not None and idx != prev:
            transitions.append((behavior_classes[prev], behavior_classes[idx]))
        prev = idx

    # Emotion descriptions for captions
    emotion_descriptions = {
        'relax': "relaxed and content",
        'happy': "happy and playful",
        'angry': "a bit upset. Give them some space",
        'frown': "a little sad. Maybe some cuddles?",
        'alert': "alert and attentive"
    }

    # Build a detailed, friendly caption
    if len(set(label_list)) == 1:
        desc = emotion_descriptions.get(final_emotion, final_emotion)
        caption = f"Your dog was {desc} throughout the video!"
        timeline_summary = f"Mood: {final_emotion} throughout."
    elif transitions:
        first, last = behavior_classes[label_list[0]], behavior_classes[label_list[-1]]
        first_desc = emotion_descriptions.get(first, first)
        last_desc = emotion_descriptions.get(last, last)
        caption = (
            f"Your dog started out {first_desc} and ended up {last_desc}. "
            f"Watch for changes in their mood!"
        )
        transition_str = ", ".join([f"{a}→{b}" for a, b in transitions])
        timeline_summary = f"Started: {first}, Ended: {last}, Transitions: {transition_str}"
    else:
        desc = emotion_descriptions.get(final_emotion, final_emotion)
        caption = f"Your dog's mood varied, but was mostly {desc}."
        timeline_summary = f"Mostly: {final_emotion}, but with some variation."

    return {
        "emotion": final_emotion,
        "confidence": confidence,
        "caption": caption,
        "timeline": timeline,
        "timeline_summary": timeline_summary,
        "frame_sampled": len(timeline),
        "processing_time": 0.0,
        "timestamp": datetime.utcnow().isoformat(),
        "video_info": None,
        "frame_image_path": frame_image_path,
        "frame_image_url": frame_image_url
    }

# Debug helper
def log_debug_info(message):
    print(f"DEBUG: {message}")

def error_response(message):
    return {
        "emotion": "unknown",
        "confidence": 0.0,
        "caption": message,
        "processing_time": 0.0,
        "timestamp": datetime.utcnow().isoformat(),
        "video_info": None,
        "timeline_summary": None
    }
