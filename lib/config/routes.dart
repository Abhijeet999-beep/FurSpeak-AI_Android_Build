import 'package:flutter/material.dart';
import 'package:furspeak_ai/screens/splash_screen.dart';
import 'package:furspeak_ai/screens/home_screen.dart';
import 'package:furspeak_ai/screens/camera_screen.dart';
import 'package:furspeak_ai/screens/chat_screen.dart';
import 'package:furspeak_ai/screens/profile_screen.dart';
import 'package:furspeak_ai/screens/login_screen.dart';
import 'package:furspeak_ai/screens/signup_screen.dart';
import 'package:furspeak_ai/screens/reset_password_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authSelection = '/auth-selection';
  static const String guestModeWarning = '/guest-mode-warning';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String capture = '/capture';
  static const String upload = '/upload';
  static const String result = '/result';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String camera = '/camera';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case camera:
        return MaterialPageRoute(builder: (_) => const CameraScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                body: Center(child: Text('Forgot Password Page (TODO)'))));
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
