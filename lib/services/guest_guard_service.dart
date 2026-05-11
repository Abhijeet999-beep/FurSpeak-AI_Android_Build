import '../providers/auth_provider.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// GuestGuardService
///
/// Centralized logic for guest user restrictions and conversion prompts.
/// Restored as part of the UX stabilization rollback.
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class GuestGuardService {
  GuestGuardService._();

  /// Returns true if the user has full access (not a guest).
  static bool hasFullAccess(AuthProvider auth) {
    return !auth.isGuest && auth.isAuthenticated;
  }

  /// Determines if a guest user should be prompted to create an account.
  /// Triggered after a certain number of scans or specific interactions.
  static bool shouldShowConversionPrompt(AuthProvider auth) {
    return auth.isGuest && 
           !auth.guestConversionDismissed && 
           auth.guestScanCount >= 2;
  }
}
