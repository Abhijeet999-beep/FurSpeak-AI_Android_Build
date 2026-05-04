/// AppSessionState — Immutable, single source of truth for GoRouter redirect.
///
/// This is a pure value object. It contains NO logic, NO async, NO side-effects.
/// The router's redirect function reads this to make deterministic decisions.
class AppSessionState {
  /// True once the auth listener has fully resolved (Firebase + Firestore + Isar).
  final bool isReady;

  /// True if a Firebase user exists (authenticated or anonymous).
  final bool isAuthenticated;

  /// True if the current Firebase user is anonymous (guest mode).
  final bool isGuest;

  /// True if the user has completed the onboarding flow.
  final bool hasCompletedOnboarding;

  /// True if the user has at least one dog profile saved.
  final bool isProfileComplete;

  const AppSessionState({
    required this.isReady,
    required this.isAuthenticated,
    required this.isGuest,
    required this.hasCompletedOnboarding,
    required this.isProfileComplete,
  });

  /// Default state before any initialization.
  static const initial = AppSessionState(
    isReady: false,
    isAuthenticated: false,
    isGuest: false,
    hasCompletedOnboarding: false,
    isProfileComplete: false,
  );

  @override
  String toString() =>
      'AppSessionState('
      'ready:$isReady, '
      'auth:$isAuthenticated, '
      'guest:$isGuest, '
      'onboarding:$hasCompletedOnboarding, '
      'profile:$isProfileComplete)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSessionState &&
          isReady == other.isReady &&
          isAuthenticated == other.isAuthenticated &&
          isGuest == other.isGuest &&
          hasCompletedOnboarding == other.hasCompletedOnboarding &&
          isProfileComplete == other.isProfileComplete;

  @override
  int get hashCode => Object.hash(
        isReady,
        isAuthenticated,
        isGuest,
        hasCompletedOnboarding,
        isProfileComplete,
      );
}
