# Contributing to FurSpeak AI

Thank you for your interest in contributing to FurSpeak AI! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x or higher)
- Python 3.8+
- Git
- Android Studio / Xcode (for mobile development)

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   git clone https://github.com/Abhijeet999-beep/FurSpeak-AI_android-build.git
   cd FurSpeak-AI_android-build
   ```

2. **Set up Flutter frontend**
   ```bash
   flutter pub get
   flutter doctor
   ```

3. **Set up Python backend**
   ```bash
   cd backend
   python -m venv venv
   # Windows
   .\venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your actual values
   ```

## 🧪 Testing

### Frontend Tests
```bash
flutter test --coverage
flutter analyze
dart format --set-exit-if-changed .
```

### Backend Tests
```bash
cd backend
pytest tests/ --cov=. --cov-report=term-missing
black --check .
flake8 .
```

## 📝 Code Style

### Flutter/Dart
- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for issues
- Format code with `dart format`

### Python
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use `black` for code formatting
- Use `flake8` for linting
- Maximum line length: 127 characters

## 🔧 Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write tests for new functionality
   - Update documentation if needed
   - Ensure all tests pass

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

4. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## 📋 Pull Request Guidelines

- **Title**: Use conventional commit format (e.g., "feat: add emotion detection")
- **Description**: Clearly describe what the PR does and why
- **Tests**: Ensure all tests pass
- **Documentation**: Update relevant documentation
- **Screenshots**: Include screenshots for UI changes

### Commit Message Format
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

## 🐛 Reporting Issues

When reporting issues, please include:
- **Description**: Clear description of the problem
- **Steps to reproduce**: Detailed steps to reproduce the issue
- **Expected behavior**: What you expected to happen
- **Actual behavior**: What actually happened
- **Environment**: OS, Flutter version, Python version
- **Screenshots**: If applicable

## 📚 Documentation

- Keep documentation up to date
- Use clear, concise language
- Include code examples where helpful
- Update README.md for significant changes

## 🤝 Code Review

- Be respectful and constructive
- Focus on the code, not the person
- Provide specific, actionable feedback
- Ask questions if something is unclear

## 📄 License

By contributing to FurSpeak AI, you agree that your contributions will be licensed under the MIT License.

## 🆘 Need Help?

- Check existing issues and discussions
- Ask questions in the issues section
- Contact the maintainers

Thank you for contributing to FurSpeak AI! 🐕✨
