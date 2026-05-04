import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // CURRENT USER
  User? get currentUser => _auth.currentUser;

  bool get isAuthenticated => currentUser != null;
  bool get isGuest => currentUser?.isAnonymous ?? false;

  // SIGNOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    if (currentUser?.isAnonymous == true) {
      try {
        return await currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // If the credential is in use, sign in to the existing account
          return await _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }
    return await _auth.signInWithCredential(credential);
  }

  // SIGN UP
  Future<UserCredential> signUp({required String email, required String password}) async {
    if (currentUser?.isAnonymous == true) {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      try {
        return await currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          return await _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    return await signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      debugPrint("USER CANCELLED GOOGLE SIGN-IN");
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("FIREBASE SIGN-IN SUCCESS: ${result.user}");
      return result;
    } catch (e) {
      debugPrint("FIREBASE SIGN-IN ERROR: $e");
      rethrow;
    }
  }

  Future<UserCredential> continueAsGuest() async {
    return await _auth.signInAnonymously();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<bool> isEmailVerified() async {
    return currentUser?.emailVerified ?? false;
  }
}