import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/presentation/screens/splash_screen.dart';
import 'package:furspeak_ai/presentation/screens/onboarding_screen.dart';
import 'package:furspeak_ai/presentation/screens/guest_mode_warning_screen.dart';
import 'package:furspeak_ai/presentation/screens/home_screen.dart';
import 'package:furspeak_ai/presentation/screens/history_screen.dart';
import 'package:furspeak_ai/presentation/screens/result_screen.dart';
import 'package:furspeak_ai/presentation/screens/settings_screen.dart';
import 'package:furspeak_ai/presentation/screens/preview_screen.dart';
import 'package:furspeak_ai/presentation/screens/video_trimmer_screen.dart';
import 'package:furspeak_ai/presentation/screens/camera_screen.dart';
import 'package:furspeak_ai/presentation/screens/login_screen.dart';
import 'package:furspeak_ai/presentation/screens/signup_screen.dart';
import 'package:furspeak_ai/presentation/screens/profile_setup_screen.dart';
import 'package:furspeak_ai/widgets/root_nav_shell.dart';
import 'package:furspeak_ai/widgets/error_widget.dart';
import 'package:furspeak_ai/services/auth_service.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String guestModeWarning = '/guest-warning';
  static const String home = '/home';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String result = '/result';
  static const String login = '/login';
  static const String preview = '/preview';
  static const String trim = '/trim';
  static const String camera = '/camera';
  static const String signup = '/signup';
  static const String profileSetup = '/profile-setup';

  static final List<String> publicRoutes = [
    splash,
    onboarding,
    guestModeWarning,
    login,
  ];

  static String? _authGuard(BuildContext context, GoRouterState state) {
    final authService = AuthService();
    final isGuest = authService.isGuest;
    final isAuthenticated = authService.isAuthenticated;
    final currentPath = state.matchedLocation;
    if (publicRoutes.contains(currentPath)) {
      return null;
    }
    if (!isAuthenticated && !isGuest) {
      return login;
    }
    return null;
  }

  static String? _guestGuard(BuildContext context, GoRouterState state) {
    final authService = AuthService();
    final currentPath = state.matchedLocation;
    if (authService.isGuest && currentPath == history) {
      return guestModeWarning;
    }
    return null;
  }

  static int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authRedirect = _authGuard(context, state);
      if (authRedirect != null) return authRedirect;
      final guestRedirect = _guestGuard(context, state);
      if (guestRedirect != null) return guestRedirect;
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => OnboardingScreen(
          onComplete: () => context.go(login),
        ),
      ),
      GoRoute(
        path: guestModeWarning,
        builder: (context, state) => GuestModeWarningScreen(
          onContinue: () => context.go(home),
          onSignIn: () => context.go(login),
        ),
      ),
      GoRoute(
        path: camera,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: result,
        builder: (context, state) {
          final result = state.extra as Map<String, dynamic>;
          return ResultScreen(result: result);
        },
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
        redirect: (context, state) {
          final authService = AuthService();
          if (!authService.isAuthenticated) {
            return guestModeWarning;
          }
          return null;
        },
      ),
      GoRoute(
        path: preview,
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return PreviewScreen(
            filePath: params['filePath'] as String,
            isVideo: params['isVideo'] as bool,
          );
        },
      ),
      GoRoute(
        path: trim,
        builder: (context, state) {
          final videoPath = state.extra as String;
          return VideoTrimmerScreen(
            videoPath: videoPath,
            onTrimmed: (trimmedPath) {
              context.pop(trimmedPath);
            },
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => RootNavShell(
          child: child,
          selectedIndex: _getSelectedIndex(state.matchedLocation),
        ),
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/detect',
            builder: (context, state) =>
                const HomeScreen(), // TODO: Add DetectScreen
          ),
          GoRoute(
            path: history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(home),
        ),
      ),
      body: AppErrorWidget(
        title: 'Page Not Found',
        message:
            'The page you are looking for does not exist or is not available.',
        icon: Icons.error_outline,
        onRetry: () => context.go(home),
      ),
    ),
  );
}

extension GoRouterExtension on BuildContext {
  void goSplash() => go(AppRoutes.splash);
  void goOnboarding() => go(AppRoutes.onboarding);
  void goGuestWarning() => go(AppRoutes.guestModeWarning);
  void goHome() => go(AppRoutes.home);
  void goHistory() => go(AppRoutes.history);
  void goSettings() => go(AppRoutes.settings);
  void goResult(Map<String, dynamic> result) =>
      go(AppRoutes.result, extra: result);
  void goPreview(String filePath, bool isVideo) =>
      go(AppRoutes.preview, extra: {'filePath': filePath, 'isVideo': isVideo});
  void goTrim(String videoPath) => go(AppRoutes.trim, extra: videoPath);
  void goCamera() => go(AppRoutes.camera);
  void goLogin() => go(AppRoutes.login);
  void goSignUp() => go(AppRoutes.signup);
  void goProfileSetup() => go(AppRoutes.profileSetup);
}
