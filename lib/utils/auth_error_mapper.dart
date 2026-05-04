import 'package:flutter/foundation.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';

class AuthErrorMapper {
  static String getErrorMessage(AuthErrorType type) {
    debugPrint('[AuthError] $type @ ${DateTime.now().toIso8601String()}');
    switch (type) {
      case AuthErrorType.network:
        return 'Please check your internet connection.';
      case AuthErrorType.invalidOtp:
        return 'Invalid code submitted. Please try again.';
      case AuthErrorType.userCancelled:
        // By returning an empty string, the UI can choose not to show a snackbar
        return '';
      case AuthErrorType.invalidCredentials:
        return 'Incorrect credentials. Please try again.';
      case AuthErrorType.emailInUse:
        return 'This email is already taken. Try signing in instead!';
      case AuthErrorType.unknown:
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }
}
