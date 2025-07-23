# 🐕 FurSpeak AI

<div align="center">
  <img src="assets/images/app_logo.png" alt="FurSpeak AI Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
  [![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org)
  [![FastAPI](https://img.shields.io/badge/FastAPI-0.68.0+-blue.svg)](https://fastapi.tiangolo.com)
  [![YOLOv5](https://img.shields.io/badge/YOLOv5-Latest-orange.svg)](https://github.com/ultralytics/yolov5)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
  [![CI/CD](https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build/actions/workflows/ci.yml)
  [![Codecov](https://codecov.io/gh/Abhijeet999-beep/FurSpeak-AI_android-build/branch/main/graph/badge.svg)](https://codecov.io/gh/Abhijeet999-beep/FurSpeak-AI_android-build)
  [![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
</div>

## 🌟 Overview

FurSpeak AI is an innovative mobile application that uses artificial intelligence to detect and interpret dog emotions through image and video analysis. Our app helps pet owners better understand their furry friends by providing real-time emotion detection and historical insights.

### ✨ Key Features

- 🎯 Real-time dog emotion detection
- 📸 Image and video analysis
- 📊 Emotion history tracking
- 👤 User profiles and authentication
- 🌙 Offline mode support
- 🔄 Cross-device synchronization

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.x or higher)
- Python 3.8+
- Git
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build.git
   cd FurSpeak-AI_android-build
   ```

2. Frontend Setup
   ```bash
   # Install Flutter dependencies
   flutter pub get
   
   # Run the app
   flutter run
   ```

3. Backend Setup
   ```bash
   # Create virtual environment
   python -m venv venv
   
   # Activate virtual environment
   # Windows
   .\venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   
   # Install dependencies
   pip install -r backend/requirements.txt
   
   # Start the server
   cd backend
   uvicorn main:app --reload
   ```

## 🛠️ Tech Stack

### Frontend
- Flutter
- Riverpod (State Management)
- Hive (Local Storage)
- Supabase (Backend as a Service)

### Backend
- FastAPI
- YOLOv11 (ML Model)
- OpenCV
- PyTorch

## 📸 App Screenshots

Here are some screenshots of the FurSpeak AI app:

<div align="center">
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_1.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_2.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_3.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_4.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_5.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_6.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_7.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_8.jpg" width="200"/>
  <img src="https://raw.githubusercontent.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/master/assets/screenshots/Screenshot_9.jpg" width="200"/>
</div>
## 🏗️ Project Structure

```
furspeak-ai/
├── lib/                    # Flutter frontend
│   ├── config/            # App configuration
│   ├── data/              # Data layer
│   ├── models/            # Data models
│   ├── presentation/      # UI screens
│   ├── services/          # Business logic
│   └── widgets/           # Reusable components
├── backend/               # Python backend
│   ├── models/           # ML models
│   ├── detect_utils.py   # Detection utilities
│   └── main.py           # FastAPI server
└── assets/               # Images, fonts, etc.
    ├── images/           # App logo
    └── screenshots/      # App screenshots
```

## 🔧 Development

### Running Tests
```bash
# Frontend tests
flutter test

# Backend tests
pytest backend/tests
```

### Code Style
```bash
# Frontend
flutter format lib/
flutter analyze

# Backend
black backend/
flake8 backend/
```

## 📈 Contributing

1. Fork the repository: `https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build.git`
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [YOLOv11](https://github.com/ultralytics/yolov5) for the ML model
- [Flutter](https://flutter.dev) for the UI framework
- [FastAPI](https://fastapi.tiangolo.com) for the backend framework
- [Supabase](https://supabase.com) for the backend services

## 📞 Contact

Abhijeet Singh - [@linkedin](https://www.linkedin.com/public-profile/settings)
Project Link: [https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build](https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build)

---

<div align="center">
  Made with ❤️ by Abhijeet Singh
</div>
