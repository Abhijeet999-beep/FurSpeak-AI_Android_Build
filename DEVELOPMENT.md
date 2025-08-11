# Development Guide

This document provides comprehensive information for developers working on FurSpeak AI.

## 🏗️ Architecture Overview

### Frontend (Flutter)
- **State Management**: BLoC pattern with flutter_bloc
- **Navigation**: GoRouter for declarative routing
- **Storage**: Isar database for local storage, Supabase for cloud sync
- **UI**: Material Design 3 with custom theming
- **Testing**: Unit tests, widget tests, and integration tests

### Backend (Python/FastAPI)
- **Framework**: FastAPI with async support
- **ML Models**: YOLOv8 for dog detection, custom model for emotion classification
- **Image Processing**: OpenCV for video frame extraction and processing
- **API**: RESTful endpoints with automatic documentation
- **Testing**: Pytest with coverage reporting

## 🚀 Development Setup

### Prerequisites
```bash
# Flutter
flutter --version  # Should be 3.x or higher

# Python
python --version  # Should be 3.8 or higher

# Git
git --version

# Node.js (for some development tools)
node --version
```

### Environment Setup
1. **Clone and setup**
   ```bash
   git clone https://github.com/Abhijeet999-beep/FurSpeak-AI_Android_Build.git
   cd FurSpeak-AI_Android_Build
   ```

2. **Frontend setup**
   ```bash
   flutter pub get
   flutter doctor
   ```

3. **Backend setup**
   ```bash
   cd backend
   python -m venv venv
   # Windows
   .\venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **Environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your actual values
   ```

## 🧪 Testing Strategy

### Frontend Testing
```bash
# Run all tests
flutter test --coverage

# Run specific test file
flutter test test/services_test.dart

# Analyze code
flutter analyze

# Format code
dart format lib/
```

### Backend Testing
```bash
cd backend

# Run all tests
pytest tests/ --cov=. --cov-report=term-missing

# Run specific test file
pytest tests/test_main.py -v

# Check code formatting
black --check .

# Lint code
flake8 .
```

### Test Coverage
- **Frontend**: Aim for >80% coverage
- **Backend**: Aim for >90% coverage
- **Critical paths**: 100% coverage required

## 🔧 Code Quality

### Flutter/Dart Standards
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` before committing
- Format code with `dart format`
- Follow BLoC pattern for state management

### Python Standards
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints for all functions
- Maximum line length: 127 characters
- Use `black` for formatting
- Use `flake8` for linting

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests are included and pass
- [ ] Documentation is updated
- [ ] No debug code left in production
- [ ] Error handling is appropriate
- [ ] Performance considerations addressed

## 📱 Flutter Development

### Project Structure
```
lib/
├── config/          # App configuration
├── data/            # Data layer (models, services)
├── models/          # Data models
├── presentation/    # UI screens and widgets
├── services/        # Business logic
└── widgets/         # Reusable components
```

### Key Dependencies
- **go_router**: Navigation
- **flutter_bloc**: State management
- **isar**: Local database
- **supabase_flutter**: Backend services
- **camera**: Camera functionality
- **image_picker**: Image selection

### State Management
```dart
// Example BLoC structure
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Implementation
  }
}
```

## 🐍 Python Backend Development

### Project Structure
```
backend/
├── models/          # ML models
├── tests/           # Test files
├── main.py          # FastAPI application
├── detect_utils.py  # ML utilities
└── requirements.txt # Dependencies
```

### API Endpoints
- `POST /detect/`: Process images/videos for emotion detection
- `GET /docs`: Interactive API documentation
- `GET /health`: Health check endpoint

### ML Pipeline
1. **Input Validation**: Check file type and size
2. **Dog Detection**: Use YOLOv8 to detect dogs
3. **ROI Extraction**: Extract region of interest
4. **Emotion Classification**: Use custom model for emotion detection
5. **Response Generation**: Format and return results

### Error Handling
```python
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "detail": str(exc)}
    )
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
1. **Frontend Job**: Flutter tests and analysis
2. **Backend Job**: Python tests and linting
3. **Build Job**: APK and app bundle creation
4. **Deploy Job**: Backend deployment

### Pre-commit Hooks
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## 📊 Performance Monitoring

### Frontend Performance
- Use `flutter run --profile` for performance testing
- Monitor frame rates with Flutter Inspector
- Profile memory usage with DevTools

### Backend Performance
- Monitor API response times
- Profile ML model inference time
- Track memory usage during processing

## 🐛 Debugging

### Flutter Debugging
```bash
# Run in debug mode
flutter run

# Enable verbose logging
flutter run --verbose

# Use Flutter Inspector for UI debugging
flutter run --debug
```

### Python Debugging
```python
import logging
logging.basicConfig(level=logging.DEBUG)

# Use pdb for debugging
import pdb; pdb.set_trace()
```

### Common Issues
1. **Import errors**: Check package dependencies
2. **ML model loading**: Verify model file paths
3. **Camera permissions**: Check Android/iOS permissions
4. **Memory issues**: Monitor ML model memory usage

## 📚 Documentation

### Code Documentation
- Use docstrings for all public functions
- Include examples in docstrings
- Document complex algorithms
- Keep README.md updated

### API Documentation
- FastAPI automatically generates OpenAPI docs
- Include request/response examples
- Document error codes and messages

## 🚀 Deployment

### Frontend Deployment
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build for web
flutter build web
```

### Backend Deployment
```bash
# Install dependencies
pip install -r requirements.txt

# Run with uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000

# Use gunicorn for production
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
```

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `develop`
2. Make changes and write tests
3. Ensure all tests pass
4. Create pull request
5. Code review and approval
6. Merge to `develop`
7. Release to `main`

### Code Review Process
- All changes require review
- Tests must pass before merge
- Documentation updates required
- Performance impact assessment

## 📞 Support

### Getting Help
- Check existing issues and discussions
- Ask questions in the issues section
- Contact maintainers directly
- Join community discussions

### Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [YOLOv8 Documentation](https://docs.ultralytics.com/)
- [Project Wiki](https://github.com/Abhijeet999-beep/FurSpeak-AI_Android_Build/wiki)

---

**Happy Coding! 🐕✨**
