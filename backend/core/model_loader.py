import torch
from ultralytics import YOLO
import logging

logger = logging.getLogger("FurSpeak-ModelLoader")


class ModelLoader:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ModelLoader, cls).__new__(cls)
            cls._instance.device = None
            cls._instance.dog_detector = None
            cls._instance.behavior_model = None
            cls._instance._initialized = False
        return cls._instance

    def initialize(self):
        if self._initialized:
            return  # Already loaded

        from backend.core.config import settings

        self.device = self._detect_device()
        
        # O1 fix: Limit threads on CPU to reduce memory overhead
        if self.device.type == "cpu":
            torch.set_num_threads(1)
            torch.set_num_interop_threads(1)
            logger.info("CPU detected: Limiting torch threads to 1 for low-memory stability.")

        logger.info(f"Initializing YOLO models on device: {self.device}")

        try:
            self.dog_detector = YOLO(settings.DOG_DETECTOR_MODEL_PATH)
            self.behavior_model = YOLO(settings.BEHAVIOR_MODEL_PATH)

            # Move models to fixed device enforcing no runtime switching
            self.dog_detector.to(self.device)
            self.behavior_model.to(self.device)
            
            # O2 fix: Fuse layers for optimized inference memory/speed
            self.dog_detector.fuse()
            self.behavior_model.fuse()
            
            self._initialized = True
            logger.info("Models loaded and fused successfully")
        except Exception as e:
            logger.error(f"Model loading failed: {e}")
            self.dog_detector = None
            self.behavior_model = None
            self._initialized = False

    def _detect_device(self):
        if torch.cuda.is_available():
            return torch.device("cuda")
        return torch.device("cpu")

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
        """Returns canonical emotion labels from config (single source of truth)."""
        from backend.core.config import settings

        return settings.EMOTION_CLASSES


# Singleton instance
model_loader = ModelLoader()
