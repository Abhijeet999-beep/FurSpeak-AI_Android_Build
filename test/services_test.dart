import 'package:flutter_test/flutter_test.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/services/emotion_service.dart';

void main() {
  group('Services Tests', () {
    test('AuthService initialization', () {
      final authService = AuthService();
      expect(authService, isNotNull);
    });

    test('EmotionService initialization', () {
      final emotionService = EmotionService();
      expect(emotionService, isNotNull);
    });
  });
}
