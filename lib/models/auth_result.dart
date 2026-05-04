import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Lightweight wrapper that mirrors the Supabase `AuthResponse` interface.
/// Keeps all call-sites (`response.user != null`) working unchanged.
class AuthResult {
  final firebase_auth.User? user;

  const AuthResult({this.user});
}
