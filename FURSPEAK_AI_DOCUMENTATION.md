# FurSpeak AI - Complete Project Documentation

## 📱 Project Overview

FurSpeak AI is a sophisticated mobile application that uses artificial intelligence to detect and interpret dog emotions through image and video analysis. The app features a delightful pastel-themed UI and provides both guest and authenticated user experiences.

### What It Does
- Analyzes dog facial expressions and body language
- Provides real-time emotion detection
- Stores historical emotion data
- Offers personalized insights about your dog's emotional state

### Significance
- Helps pet owners better understand their dogs
- Provides scientific insights into dog behavior
- Creates a bridge between human and canine communication
- Aids in early detection of potential health or behavioral issues

## 🏗️ Architecture Overview

### Frontend (Flutter)
```
lib/
├── config/         # App configuration and constants
├── data/          # Data layer (repositories, data sources)
├── models/        # Data models and entities
├── presentation/  # UI screens and widgets
├── services/      # Business logic and services
├── theme/         # App theming and styling
└── widgets/       # Reusable UI components
```

### What Each Directory Does
- **config/**: Stores app-wide settings, API endpoints, and environment variables
- **data/**: Handles data operations, API calls, and local storage
- **models/**: Defines data structures and business objects
- **presentation/**: Contains all UI screens and visual components
- **services/**: Implements business logic and third-party integrations
- **theme/**: Manages app styling, colors, and typography
- **widgets/**: Houses reusable UI components

### Backend (Python/FastAPI)
```
backend/
├── models/        # ML models and utilities
├── detect_utils.py # Detection utilities
├── main.py        # FastAPI server entry point
└── requirements.txt # Python dependencies
```

### What Each Backend Component Does
- **models/**: Contains trained ML models for emotion detection
- **detect_utils.py**: Provides helper functions for image processing
- **main.py**: Sets up the API server and defines endpoints
- **requirements.txt**: Lists all Python package dependencies

## 🎨 Design System

### Color Palette
- Background: `#FFFAF2` (Vanilla Cream) - Creates a warm, welcoming feel
- Primary: `#7E8CE0` (Soft Periwinkle) - Main action color for buttons and links
- Accent: `#FFB347` (Gentle Orange) - Highlights important actions
- Tertiary: `#FFE084` (Pastel Yellow) - Used for warnings and notifications

### Typography
- Headings: Poppins Bold - Ensures clear hierarchy and readability
- Body: Inter Medium - Optimized for comfortable reading on mobile

### UI Components
- Buttons: 18px border radius with soft shadows - Creates a friendly, approachable feel
- Cards: 24px border radius with elevation - Organizes content in digestible chunks
- Text: Warm gray tones - Reduces eye strain during extended use
- Chips: Mint green, peach, and pink variants - Makes emotion tags visually distinct

## 🔄 Core Features

### 1. Authentication System
- Guest mode with limited features
- Email/Google authentication
- Biometric authentication option
- Secure session management

#### How It Works
1. New users can try the app without signing up
2. Full features require account creation
3. Multiple sign-in options for convenience
4. Secure token-based authentication

### 2. Dog Profile Management
- Custom avatar selection
- Breed information
- Profile customization
- Data persistence

#### Why It Matters
- Creates a personal connection with the app
- Enables breed-specific emotion detection
- Allows tracking of multiple dogs
- Maintains user preferences

### 3. Emotion Detection
- Real-time camera capture
- Video recording (60s limit)
- Image upload support
- Emotion analysis with confidence scores

#### Technical Process
1. Image/video capture
2. Pre-processing for ML model
3. Emotion analysis using YOLOv5
4. Confidence score calculation
5. Results presentation

### 4. History & Analytics
- Emotion timeline
- Filtered views by emotion type
- Weekly summaries
- Data visualization

#### Benefits
- Tracks emotional patterns over time
- Identifies behavioral changes
- Provides actionable insights
- Helps in training and care

## 💾 Data Management

### Local Storage (Hive)
- Encrypted data storage
- Offline capability
- Guest data management
- Cache management

#### How It Works
1. Data is encrypted before storage
2. Works offline for basic features
3. Syncs when online
4. Manages temporary guest data

### Cloud Storage (Supabase)
- User authentication
- Profile data
- Emotion history
- Media storage

#### Benefits
- Secure data backup
- Cross-device synchronization
- Scalable storage solution
- Real-time updates

## 🔐 Security Features

### Authentication
- JWT token management
- Session auto-refresh
- Secure password handling
- Biometric integration

#### Security Measures
1. Encrypted token storage
2. Regular session validation
3. Secure password hashing
4. Biometric fallback

### Data Protection
- Row-level security
- Encrypted storage
- Secure API endpoints
- Access control

#### Implementation
1. Database-level security
2. End-to-end encryption
3. API authentication
4. Role-based access

## 🚀 Development Guidelines

### Code Organization
1. Follow feature-first architecture
2. Maintain separation of concerns
3. Use dependency injection
4. Implement proper error handling

#### Best Practices
- Keep related code together
- Use clear naming conventions
- Document complex logic
- Handle errors gracefully

### State Management
- Use Riverpod for state management
- Implement proper state persistence
- Handle offline/online states
- Manage loading states

#### Why Riverpod?
- Type-safe state management
- Easy testing
- Dependency injection
- Code organization

### Testing Strategy
1. Unit tests for business logic
2. Widget tests for UI components
3. Integration tests for features
4. Performance testing

#### Testing Approach
- Test critical paths first
- Mock external dependencies
- Use test coverage tools
- Regular performance profiling

## 📱 App Flow

1. **Splash Screen**
   - Brand introduction
   - Loading animation
   - Quick start option

2. **Onboarding**
   - Feature showcase
   - User guidance
   - Skip option

3. **Authentication**
   - Multiple sign-in options
   - Guest mode access
   - Profile creation

4. **Main Features**
   - Emotion detection
   - History viewing
   - Profile management
   - Settings

## 🔧 Technical Requirements

### Frontend
- Flutter SDK (version 3.x or higher)
- Dart 2.x
- Required packages:
  - go_router (^10.0.0) - For navigation
  - flutter_bloc (^8.1.0) - For state management
  - supabase_flutter (^1.0.0) - For backend integration
  - hive (^2.2.3) - For local storage
  - camera (^0.10.0) - For image/video capture
  - path_provider (^2.0.0) - For file management
  - permission_handler (^10.0.0) - For device permissions

#### Development Environment Setup
1. Install Flutter SDK
   ```bash
   # Windows
   flutter doctor
   flutter pub get
   ```

2. Configure IDE
   - Install Flutter and Dart plugins
   - Enable format on save
   - Configure linting rules

3. Setup Local Development
   ```bash
   # Clone repository
   git clone [repository-url]
   
   # Install dependencies
   flutter pub get
   
   # Run the app
   flutter run
   ```

### Backend
- Python 3.8+
- FastAPI 0.68.0+
- YOLOv5
- Required packages in requirements.txt:
  ```
  fastapi==0.68.0
  uvicorn==0.15.0
  python-multipart==0.0.5
  numpy==1.21.0
  opencv-python==4.5.3
  torch==1.9.0
  ```

#### Backend Setup
1. Create virtual environment
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   .\venv\Scripts\activate   # Windows
   ```

2. Install dependencies
   ```bash
   pip install -r requirements.txt
   ```

3. Start server
   ```bash
   uvicorn main:app --reload
   ```

## 🔄 Core Features - Technical Deep Dive

### 1. Authentication System

#### Implementation Details
```dart
// Authentication Service
class AuthService {
  final SupabaseClient _client;
  
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signIn(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
```

#### Security Measures
1. Token Management
   - JWT tokens with 1-hour expiration
   - Automatic refresh mechanism
   - Secure storage using flutter_secure_storage

2. Session Handling
   - Persistent sessions for authenticated users
   - Guest sessions with limited lifetime
   - Automatic session cleanup

### 2. Emotion Detection System

#### ML Pipeline
1. Image Preprocessing
   ```python
   def preprocess_image(image):
       # Resize to model input size
       resized = cv2.resize(image, (640, 640))
       # Normalize pixel values
       normalized = resized / 255.0
       # Convert to tensor
       tensor = torch.from_numpy(normalized).float()
       return tensor
   ```

2. Model Inference
   ```python
   def detect_emotion(image):
       # Load model
       model = torch.hub.load('ultralytics/yolov5', 'custom', 
                            path='models/dog_emotion.pt')
       
       # Run inference
       results = model(image)
       
       # Process results
       emotions = results.pandas().xyxy[0]
       return emotions
   ```

3. Confidence Scoring
   ```python
   def calculate_confidence(predictions):
       # Weight different factors
       face_confidence = predictions['face_confidence']
       body_confidence = predictions['body_confidence']
       
       # Calculate weighted average
       final_confidence = (0.7 * face_confidence + 
                          0.3 * body_confidence)
       return final_confidence
   ```

### 3. Data Management

#### Local Storage (Hive)
```dart
// Hive Service
class HiveService {
  static const String _boxName = 'furspeak_data';
  
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }
  
  Future<void> saveEmotionData(EmotionData data) async {
    final box = Hive.box(_boxName);
    await box.put(data.id, data.toJson());
  }
  
  Future<List<EmotionData>> getEmotionHistory() async {
    final box = Hive.box(_boxName);
    return box.values
        .map((data) => EmotionData.fromJson(data))
        .toList();
  }
}
```

#### Cloud Storage (Supabase)
```dart
// Supabase Service
class SupabaseService {
  final SupabaseClient _client;
  
  Future<void> uploadImage(File image) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage
        .from('dog_images')
        .upload(fileName, image);
  }
  
  Future<List<EmotionData>> syncData() async {
    final response = await _client
        .from('emotion_data')
        .select()
        .order('created_at', ascending: false);
    return response.map((data) => 
        EmotionData.fromJson(data)).toList();
  }
}
```

## 🚀 Development Guidelines - Extended

### Code Organization

#### Feature-First Architecture
```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── emotion_detection/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── core/
    ├── config/
    ├── services/
    └── utils/
```

#### Dependency Injection
```dart
// Service Locator
final sl = GetIt.instance;

void initDependencies() {
  // Services
  sl.registerLazySingleton(() => AuthService());
  sl.registerLazySingleton(() => EmotionDetectionService());
  
  // Repositories
  sl.registerLazySingleton(() => EmotionRepository(
    localDataSource: sl(),
    remoteDataSource: sl(),
  ));
  
  // Use Cases
  sl.registerLazySingleton(() => DetectEmotionUseCase(
    repository: sl(),
  ));
}
```

### State Management

#### Riverpod Implementation
```dart
// Emotion State
class EmotionState {
  final bool isLoading;
  final List<EmotionData> emotions;
  final String? error;
  
  EmotionState({
    this.isLoading = false,
    this.emotions = const [],
    this.error,
  });
}

// Emotion Provider
final emotionProvider = StateNotifierProvider<EmotionNotifier, EmotionState>((ref) {
  return EmotionNotifier(
    repository: ref.watch(emotionRepositoryProvider),
  );
});

// Emotion Notifier
class EmotionNotifier extends StateNotifier<EmotionState> {
  final EmotionRepository repository;
  
  EmotionNotifier({required this.repository}) : super(EmotionState());
  
  Future<void> detectEmotion(File image) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await repository.detectEmotion(image);
      state = state.copyWith(
        emotions: [...state.emotions, result],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
```

### Testing Strategy

#### Unit Tests
```dart
void main() {
  group('EmotionDetectionService', () {
    late EmotionDetectionService service;
    
    setUp(() {
      service = EmotionDetectionService();
    });
    
    test('should detect happy emotion', () async {
      // Arrange
      final image = File('test/fixtures/happy_dog.jpg');
      
      // Act
      final result = await service.detectEmotion(image);
      
      // Assert
      expect(result.emotion, equals('happy'));
      expect(result.confidence, greaterThan(0.8));
    });
  });
}
```

#### Widget Tests
```dart
void main() {
  testWidgets('EmotionDetectionScreen', (tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: EmotionDetectionScreen(),
      ),
    );
    
    // Act
    await tester.tap(find.byIcon(Icons.camera));
    await tester.pump();
    
    // Assert
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Record Video'), findsOneWidget);
  });
}
```

## 🐛 Debugging Guide - Extended

### Common Issues and Solutions

#### 1. Camera Issues
```dart
// Camera Permission Handler
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isDenied) {
    // Show permission explanation
    showDialog(
      context: context,
      builder: (context) => PermissionExplanationDialog(),
    );
  }
}

// Camera Controller Setup
final controller = CameraController(
  cameras.first,
  ResolutionPreset.high,
  enableAudio: true,
);

try {
  await controller.initialize();
} catch (e) {
  print('Camera initialization failed: $e');
}
```

#### 2. Storage Issues
```dart
// Storage Permission Handler
Future<void> requestStoragePermission() async {
  final status = await Permission.storage.request();
  if (status.isDenied) {
    // Handle permission denial
  }
}

// File Management
Future<String> getLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
```

#### 3. Network Issues
```dart
// Network Connectivity Check
Future<bool> checkConnectivity() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}

// Offline Mode Handler
class OfflineModeHandler {
  final HiveService _hiveService;
  
  Future<void> handleOfflineOperation() async {
    // Store operation in local queue
    await _hiveService.addToSyncQueue(operation);
    
    // Show offline indicator
    showOfflineBanner();
  }
}
```

### Performance Optimization

#### 1. Image Processing
```dart
// Image Compression
Future<File> compressImage(File file) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.path,
    file.path.replaceAll('.jpg', '_compressed.jpg'),
    quality: 85,
  );
  return File(result!.path);
}
```

#### 2. Memory Management
```dart
// Memory Efficient Image Loading
class MemoryEfficientImage extends StatelessWidget {
  final String url;
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: 800,
      memCacheHeight: 800,
      placeholder: (context, url) => LoadingIndicator(),
      errorWidget: (context, url, error) => ErrorWidget(),
    );
  }
}
```

## 📚 Additional Resources

### Learning Resources
- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [YOLOv5 Documentation](https://docs.ultralytics.com)
- [FastAPI Documentation](https://fastapi.tiangolo.com)

### Community Support
- [Flutter Discord](https://discord.gg/flutter)
- [Supabase Discord](https://discord.supabase.com)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Issues](https://github.com/your-repo/issues)

---

This documentation is a living document and should be updated as the project evolves. For specific implementation details, refer to the inline code documentation and comments. 