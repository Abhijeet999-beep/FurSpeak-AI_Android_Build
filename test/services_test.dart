import 'package:flutter_test/flutter_test.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('Services Tests', () {
    test('AuthService initialization', () {
      final authService = AuthService();
      expect(authService, isNotNull);
    });
  });
}
