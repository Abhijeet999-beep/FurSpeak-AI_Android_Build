import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  bool isGuest = true;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state helpers
  bool get isAuthenticated => currentUser != null && !isGuest;
  bool get isGuestMode => isGuest;

  // Initialize: nothing to do, always start as guest unless user logs in
  Future<void> initialize() async {
    isGuest = currentUser == null;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    isGuest = false;
    return response;
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    isGuest = false;
    return response;
  }

  // Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
    );
    isGuest = false;
    // After OAuth, the session is set asynchronously. Return current user/session.
    return AuthResponse(
      user: _supabase.auth.currentUser,
      session: _supabase.auth.currentSession,
    );
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    isGuest = true;
  }

  // Continue as guest
  Future<AuthResponse> continueAsGuest() async {
    final response = await _supabase.auth.signInWithPassword(
      email: 'guest@furspeak.ai',
      password: 'guest_password',
    );
    isGuest = true;
    return response;
  }
}
