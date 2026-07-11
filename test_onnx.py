import numpy as np
from ultralytics import YOLO
from backend.core.model_loader import model_loader
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("FurSpeak-Test")

loader = model_loader
dog_model = loader.get_dog_detector()
beh_model = loader.get_behavior_model()

print("\n--- Running Dummy Inference to initialize backends ---")
dummy_img = np.zeros((640, 640, 3), dtype=np.uint8)

res_dog = dog_model(dummy_img, verbose=False)
res_beh = beh_model(dummy_img, verbose=False)

print("\n--- Dog Model Verification ---")
print("Dog model object type:", type(dog_model.model))
if hasattr(dog_model.model, 'session'):
    print("Dog model ONNX Session active:", type(dog_model.model.session))
    print("Dog model Providers:", dog_model.model.session.get_providers())
else:
    print("No ONNX session found on dog_model.model")

print("\n--- Behavior Model Verification ---")
print("Behavior model object type:", type(beh_model.model))
if hasattr(beh_model.model, 'session'):
    print("Behavior model ONNX Session active:", type(beh_model.model.session))
    print("Behavior model Providers:", beh_model.model.session.get_providers())
else:
    print("No ONNX session found on beh_model.model")
