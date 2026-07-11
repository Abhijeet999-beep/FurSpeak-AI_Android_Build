import os
from ultralytics import YOLO

def export_models():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    weights_dir = os.path.join(base_dir, "ml", "weights")
    
    dog_model_path = os.path.join(weights_dir, "yolov8m.pt")
    light_dog_model_path = os.path.join(weights_dir, "yolov8n.pt")
    behavior_model_path = os.path.join(weights_dir, "best.pt")
    
    print("Exporting models to ONNX for CPU optimization...")
    
    for path in [dog_model_path, light_dog_model_path, behavior_model_path]:
        if os.path.exists(path):
            print(f"Exporting {path}...")
            model = YOLO(path)
            # Export to ONNX with dynamic quantization (best for CPU)
            # half=True for FP16
            model.export(format='onnx', half=True, dynamic=True)
            print(f"Exported {path} successfully.")
        else:
            print(f"Model {path} not found, skipping.")

if __name__ == "__main__":
    export_models()
