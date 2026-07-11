import 'package:flutter_test/flutter_test.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/models/app_session_state.dart';

void main() {
  group('AppRoutes.computeRedirect', () {
    // ── RULE 1: Not ready → /splash ─────────────────────────────────────

    test('Rule 1 — not ready, on splash → null (stay)', () {
      final session = AppSessionState(
        isReady: false,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: false,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/splash'), isNull);
    });

    test('Rule 1 — not ready, on /home → /splash', () {
      final session = AppSessionState(
        isReady: false,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: false,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/home'), '/splash');
    });

    // ── RULE 2: Not onboarded → /onboarding ────────────────────────────

    test('Rule 2 — ready but not onboarded, on /onboarding → null', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: false,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/onboarding'), isNull);
    });

    test('Rule 2 — ready but not onboarded, on /home → /onboarding', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: false,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/home'), '/onboarding');
    });

    // ── RULE 3: Not authenticated → /welcome or allow public ────────────

    test('Rule 3 — not authenticated, on /welcome → null', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/welcome'), isNull);
    });

    test('Rule 3 — not authenticated, on public route /signup → null', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/signup'), isNull);
    });

    test('Rule 3 — not authenticated, on /home → /welcome', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: false,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/home'), '/welcome');
    });

    // ── RULE 4: Authenticated non-guest, incomplete profile → /profile-setup ─

    test('Rule 4 — authenticated, not guest, no profile → /profile-setup', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/home'), '/profile-setup');
    });

    test('Rule 4 — already on /profile-setup → null', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: false,
      );
      expect(AppRoutes.computeRedirect(session, '/profile-setup'), isNull);
    });

    // ── RULE 5: Authenticated user on restricted route → /home ──────────

    test('Rule 5 — authenticated on /splash → /home', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/splash'), '/home');
    });

    test('Rule 5 — authenticated on /welcome → /home', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/welcome'), '/home');
    });

    test('Rule 5 — profile complete, on /profile-setup → /home', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/profile-setup'), '/home');
    });

    test('Rule 5 — guest user on /welcome → null (allowed for account creation/linking)', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: true,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/welcome'), isNull);
    });

    test('Rule 5 — guest user on /signup → null (allowed for account creation/linking)', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: true,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/signup'), isNull);
    });

    // ── RULE 6: Guest on restricted routes → /guest-warning ─────────────

    test('Rule 6 — guest on /history → /guest-warning', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: true,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/history'), '/guest-warning');
    });

    test('Rule 6 — guest on /settings → /guest-warning', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: true,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/settings'), '/guest-warning');
    });

    // ── RULE 7: All checks pass → null (allow navigation) ──────────────

    test('Rule 7 — fully authenticated on /home → null', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: false,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/home'), isNull);
    });

    test('Rule 7 — guest on /home → null (allowed)', () {
      final session = AppSessionState(
        isReady: true,
        isAuthenticated: true,
        isGuest: true,
        hasCompletedOnboarding: true,
        isProfileComplete: true,
      );
      expect(AppRoutes.computeRedirect(session, '/home'), isNull);
    });
  });
}
