import 'package:flutter/material.dart';
import 'package:furspeak_ai/models/app_session_state.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/presentation/screens/splash_screen.dart';
import 'package:furspeak_ai/presentation/screens/onboarding_screen.dart';
import 'package:furspeak_ai/presentation/screens/guest_mode_warning_screen.dart';
import 'package:furspeak_ai/presentation/screens/home_screen.dart';
import 'package:furspeak_ai/presentation/screens/history_screen.dart';
import 'package:furspeak_ai/presentation/screens/result_screen.dart';
import 'package:furspeak_ai/presentation/screens/settings_screen.dart';
import 'package:furspeak_ai/presentation/screens/login_screen.dart';
import 'package:furspeak_ai/presentation/screens/signup_screen.dart';
import 'package:furspeak_ai/presentation/screens/profile_setup_screen.dart';
import 'package:furspeak_ai/presentation/screens/phone_input_screen.dart';
import 'package:furspeak_ai/presentation/screens/otp_verification_screen.dart';
import 'package:furspeak_ai/presentation/screens/permission_screen.dart';
import 'package:furspeak_ai/presentation/screens/email_login_screen.dart';
import 'package:furspeak_ai/widgets/root_nav_shell.dart';
import 'package:furspeak_ai/widgets/error_widget.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:furspeak_ai/controllers/history_controller.dart';
import 'package:furspeak_ai/services/result_storage_service.dart';
// =============================================================================
// ROUTE ACCESS TABLE
// =============================================================================
//
// ┌─────────────────────┬─────────────────────────────────────────────────────┐
// │ Category            │ Routes                                            │
// ├─────────────────────┼─────────────────────────────────────────────────────┤
// │ PUBLIC              │ /welcome, /signup, /phone-login, /email-login,     │
// │ (unauthenticated)   │ /otp-verify                                       │
// ├─────────────────────┼─────────────────────────────────────────────────────┤
// │ TRANSITIONAL        │ /splash (loading), /onboarding (first-run),        │
// │ (system-managed)    │ /profile-setup (incomplete profile),               │
// │                     │ /guest-warning (guest gate), /permissions          │
// ├─────────────────────┼─────────────────────────────────────────────────────┤
// │ PROTECTED           │ /home, /history, /settings, /result               │
// │ (authenticated)     │                                                   │
// └─────────────────────┴─────────────────────────────────────────────────────┘
//
// REDIRECT RULES (evaluated top-to-bottom, first match wins):
//
// 1. NOT ready           → /splash   (loading screen)
// 2. NOT onboarded       → /onboarding
// 3. NOT authenticated   → /welcome  (unless already on a public route)
// 4. Auth + !guest +     → /profile-setup
//    !profileComplete
// 5. Auth + on a         → /home     (block re-entry to auth/onboarding)
//    restricted route
// 6. Otherwise           → null      (allow navigation)
//
// LOOP PREVENTION:
//   redirect returns null when target == current location.
// =============================================================================

class AppRoutes {
  // ─── Route Path Constants ──────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String guestModeWarning = '/guest-warning';
  static const String home = '/home';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String result = '/result';
  static const String welcome = '/welcome';
  static const String signup = '/signup';
  static const String phoneLogin = '/phone-login';
  static const String emailLogin = '/email-login';
  static const String otpVerify = '/otp-verify';
  static const String profileSetup = '/profile-setup';
  static const String permissions = '/permissions';

  // ─── Route Sets ────────────────────────────────────────────────────────────

  /// Routes accessible WITHOUT authentication.
  static const Set<String> publicRoutes = {
    welcome,
    signup,
    phoneLogin,
    emailLogin,
    otpVerify,
  };

  /// Routes that authenticated users must NOT re-enter.
  /// (Auth screens + onboarding + splash)
  static const Set<String> _restrictedWhenAuthenticated = {
    splash,
    onboarding,
    welcome,
    signup,
    phoneLogin,
    emailLogin,
    otpVerify,
  };

  /// Routes that guest users cannot access (require a real account).
  static const Set<String> guestRestrictedRoutes = {
    history,
    settings,
  };

  static const bool isProd = bool.fromEnvironment('dart.vm.product');

  // ─── PURE REDIRECT FUNCTION ────────────────────────────────────────────────
  //
  // This is a PURE function: (AppSessionState, currentPath) → String?
  //   - NO async
  //   - NO flags
  //   - NO side-effects
  //   - Deterministic: same inputs → same output, always.

  /// Computes the redirect target given the current session state and path.
  /// Returns null if no redirect is needed.
  @visibleForTesting
  static String? computeRedirect(AppSessionState session, String currentPath, {bool isEditing = false}) {
    // ── RULE 1: Not ready → stay on splash ──────────────────────────────────
    if (!session.isReady) {
      return currentPath == splash ? null : splash;
    }

    // ── RULE 2: Onboarding not completed ────────────────────────────────────
    if (!session.hasCompletedOnboarding) {
      return currentPath == onboarding ? null : onboarding;
    }

    // ── RULE 3: Not authenticated → allow public routes, else → /welcome ───
    if (!session.isAuthenticated) {
      if (publicRoutes.contains(currentPath)) {
        return null; // Already on a valid public route
      }
      return currentPath == welcome ? null : welcome;
    }

    // ── RULE 4: Authenticated non-guest without profile → /profile-setup ───
    if (!session.isGuest && !session.isProfileComplete) {
      return currentPath == profileSetup ? null : profileSetup;
    }

    // ── RULE 5: Authenticated user on restricted route → /home ──────────────
    // Guest users are allowed to access public auth routes for account upgrading/linking
    final isOnRestricted = session.isGuest
        ? (currentPath == splash || currentPath == onboarding)
        : _restrictedWhenAuthenticated.contains(currentPath);

    // Also redirect away from /profile-setup if profile is already complete and not editing
    final isProfileDone = session.isProfileComplete && currentPath == profileSetup && !isEditing;

    if (isOnRestricted || isProfileDone) {
      return currentPath == home ? null : home;
    }

    // ── RULE 6: Guest accessing restricted route → /guest-warning ──────────────
    if (session.isGuest && guestRestrictedRoutes.contains(currentPath)) {
      return currentPath == guestModeWarning ? null : guestModeWarning;
    }

    // ── RULE 7: All checks passed → allow navigation ───────────────────────
    return null;
  }

  // ─── GoRouter REDIRECT ENTRYPOINT ──────────────────────────────────────────

  static String? _redirect(
    BuildContext context,
    GoRouterState state,
    AuthProvider authProvider,
  ) {
    final session = authProvider.sessionState;
    final currentPath = state.matchedLocation;
    final isEditing = state.uri.queryParameters['edit'] == 'true';
    final target = computeRedirect(session, currentPath, isEditing: isEditing);

    debugPrint(
      'ROUTER → $session → '
      'from:$currentPath → '
      'target:${target ?? "(allow)"}',
    );

    return target;
  }

  // ─── Router Factory ────────────────────────────────────────────────────────

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: splash,
      debugLogDiagnostics: !isProd,
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(context, state, authProvider),
      routes: [
        // ── System / Transitional Routes ──────────────────────────────────
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: guestModeWarning,
          builder: (context, state) => GuestModeWarningScreen(
            onContinue: () => context.go(home),
            onSignIn: () => context.go(welcome),
          ),
        ),
        GoRoute(
          path: permissions,
          builder: (context, state) => const PermissionScreen(),
        ),
        GoRoute(
          path: profileSetup,
          builder: (context, state) => const ProfileSetupScreen(),
        ),

        // ── Auth Routes (Public) ──────────────────────────────────────────
        GoRoute(
          path: welcome,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: signup,
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: phoneLogin,
          builder: (context, state) => const PhoneInputScreen(),
        ),
        GoRoute(
          path: emailLogin,
          builder: (context, state) => const EmailLoginScreen(),
        ),
        GoRoute(
          path: otpVerify,
          builder: (context, state) => const OtpVerificationScreen(),
        ),

        // ── Protected: Result (requires ID query param) ────────────────
        GoRoute(
          path: result,
          redirect: (context, state) {
            // Pure data-guard: if id is missing → fall back to /home.
            final id = state.uri.queryParameters['id'];
            if (id == null || id.isEmpty) {
              debugPrint(
                  '⚠️ [ROUTER] /result has no valid id param → redirecting to /home');
              return home;
            }
            return null;
          },
          builder: (context, state) {
            final id = state.uri.queryParameters['id']!;
            return ResultScreen(resultId: id);
          },
        ),

        // ── Protected: Shell Navigation (Home / History / Settings) ──────
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return RootNavShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: history,
                  builder: (context, state) {
                    return ChangeNotifierProvider<HistoryController>(
                      create: (_) {
                        final storage = GetIt.instance<ResultStorageService>();
                        final controller = HistoryController(storage);
                        controller.loadHistory();
                        return controller;
                      },
                      child: const HistoryScreen(),
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: settings,
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
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
}

// =============================================================================
// Navigation Extension Methods
// =============================================================================
extension GoRouterExtension on BuildContext {
  // --- Auth & Core flows: use go() to REPLACE stack ---
  void goSplash() => go(AppRoutes.splash);
  void goOnboarding() => go(AppRoutes.onboarding);
  void goGuestWarning() => go(AppRoutes.guestModeWarning);
  void goHome() => go(AppRoutes.home);
  void goHistory() => go(AppRoutes.history);
  void goSettings() => go(AppRoutes.settings);
  void goSignUp() => go(AppRoutes.signup);
  void goProfileSetup() => go(AppRoutes.profileSetup);
  void goWelcome() => go(AppRoutes.welcome);
  void goPhoneLogin() => go(AppRoutes.phoneLogin);
  void goEmailLogin() => go(AppRoutes.emailLogin);
  void goOtpVerify() => go(AppRoutes.otpVerify);
  void goPermissions() => go(AppRoutes.permissions);

  // --- Detection flows: navigate with ID ---
  void pushResult(String resultId) =>
      go('${AppRoutes.result}?id=$resultId');
}
