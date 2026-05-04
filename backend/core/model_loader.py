import torch
from ultralytics import YOLO

class ModelLoader:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ModelLoader, cls).__new__(cls)
            cls._instance.device = None
            cls._instance.dog_detector = None
            cls._instance.behavior_model = None
            cls._instance.behavior_classes = ['relax', 'happy', 'angry', 'frown', 'alert']
        return cls._instance

    def initialize(self):
        if self.dog_detector is not None:
            return  # Already loaded
            
        from backend.core.config import Config
        self.device = self._detect_device()
        print(f"🚀 Initializing YOLO models on fixed device: {self.device}")
        
        # Load models once safely
        try:
            self.dog_detector = YOLO(Config.DOG_DETECTOR_MODEL_PATH)
            self.behavior_model = YOLO(Config.BEHAVIOR_MODEL_PATH)
            
            # Move models to fixed device enforcing no runtime switching
            self.dog_detector.to(self.device)
            self.behavior_model.to(self.device)
            print("✅ Models loaded successfully")
        except Exception as e:
            print(f"❌ Model loading failed: {e}")
            self.dog_detector = None
            self.behavior_model = None
        
    def _detect_device(self):
        if torch.cuda.is_available():
            return torch.device('cuda')
        return torch.device('cpu')

    def get_dog_detector(self):
        self.initialize()
        return self.dog_detector

    def get_behavior_model(self):
        self.initialize()
        return self.behavior_model

    def get_device(self):
        self.initialize()
        return self.device
        
    def get_classes(self):
        return self.behavior_classes

# Singleton instance
model_loader = ModelLoader()
