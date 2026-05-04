import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }
}
